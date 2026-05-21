#include <jni.h>
#include <string>
#include <fstream>
#include <sstream>
#include <vector>
#include <android/log.h>
#include "llama_cpp/include/llama.h"

#define LOG_TAG "PocketSwasthNativeAI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global state tracking for offline model
#ifndef __arm__
static struct llama_model * g_model = nullptr;
static struct llama_context * g_ctx = nullptr;
#endif
static bool g_model_loaded = false;

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_pocketswasth_pocket_1swasth_MainActivity_loadModelNative(
        JNIEnv *env, jobject thiz, jstring model_path_str) {
    
    if (model_path_str == nullptr) return JNI_FALSE;

#ifdef __arm__
    LOGE("loadModelNative: 32-bit ARM architecture is not supported for offline LLM.");
    return JNI_FALSE;
#else
    const char *path_chars = env->GetStringUTFChars(model_path_str, nullptr);
    std::string path(path_chars);
    env->ReleaseStringUTFChars(model_path_str, path_chars);

    if (g_model_loaded) {
        LOGI("loadModelNative: Model already loaded.");
        return JNI_TRUE;
    }

    LOGI("loadModelNative: Initializing llama.cpp backend...");
    llama_backend_init();

    LOGI("loadModelNative: Loading model from path: %s", path.c_str());
    llama_model_params model_params = llama_model_default_params();
    g_model = llama_load_model_from_file(path.c_str(), model_params);

    if (g_model == nullptr) {
        LOGE("loadModelNative: Failed to load model.");
        return JNI_FALSE;
    }

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048; // Max context for SmolLM
    
    g_ctx = llama_new_context_with_model(g_model, ctx_params);
    if (g_ctx == nullptr) {
        LOGE("loadModelNative: Failed to create context.");
        llama_free_model(g_model);
        g_model = nullptr;
        return JNI_FALSE;
    }

    g_model_loaded = true;
    LOGI("loadModelNative: Local SmolLM2 GGUF loaded into Llama.cpp engine successfully.");
    return JNI_TRUE;
#endif
}

JNIEXPORT jstring JNICALL
Java_com_pocketswasth_pocket_1swasth_MainActivity_inferSymptomNative(
        JNIEnv *env, jobject thiz, jstring symptoms_str, jstring language_str, jboolean is_diagnosis_mode) {

    if (!g_model_loaded) {
        return env->NewStringUTF("Error: Native AI Model is not initialized.");
    }

#ifdef __arm__
    return env->NewStringUTF("Error: Offline AI is not supported on 32-bit devices.");
#else
    if (g_ctx == nullptr || g_model == nullptr) {
        return env->NewStringUTF("Error: Engine pointers null.");
    }

    const char *symptom_chars = env->GetStringUTFChars(symptoms_str, nullptr);
    std::string query(symptom_chars);
    env->ReleaseStringUTFChars(symptoms_str, symptom_chars);

    const char *lang_chars = env->GetStringUTFChars(language_str, nullptr);
    std::string language(lang_chars);
    env->ReleaseStringUTFChars(language_str, lang_chars);

    LOGI("inferSymptomNative: Received query: %s", query.c_str());

    // Construct the LLM Prompt
    std::stringstream prompt_ss;
    prompt_ss << "<|im_start|>system\nYou are Pocket Swasth AI, a helpful medical assistant.\n";
    prompt_ss << "Respond in " << language << ".\n";
    if (is_diagnosis_mode) {
        prompt_ss << "You are in DIAGNOSIS MODE. Output must be formatted as:\n";
        prompt_ss << "**1. Possible Causes:**\n**2. What You Can Do:**\n**3. When to See a Doctor:**\n**4. Disclaimer:**\n";
    } else {
        prompt_ss << "Chat normally and naturally with the user as a friendly doctor.\n";
    }
    prompt_ss << "<|im_end|>\n<|im_start|>user\n" << query << "<|im_end|>\n<|im_start|>assistant\n";
    std::string prompt = prompt_ss.str();

    const struct llama_vocab * vocab = llama_model_get_vocab(g_model);

    // Tokenize prompt
    std::vector<llama_token> tokens(prompt.length() + 10);
    int n_tokens = llama_tokenize(vocab, prompt.c_str(), prompt.length(), tokens.data(), tokens.size(), true, true);
    if (n_tokens < 0) {
        tokens.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt.c_str(), prompt.length(), tokens.data(), tokens.size(), true, true);
    }
    tokens.resize(n_tokens);

    LOGI("inferSymptomNative: Prompt tokenized to %d tokens.", n_tokens);

    // Initialize batch
    struct llama_batch batch = llama_batch_init(2048, 0, 1);
    batch.n_tokens = tokens.size();
    for (size_t i = 0; i < tokens.size(); i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.seq_id[i][0] = 0;
        batch.n_seq_id[i] = 1;
        batch.logits[i] = false;
    }
    // Only get logits for the last token of the prompt
    batch.logits[tokens.size() - 1] = true;

    if (llama_decode(g_ctx, batch) != 0) {
        LOGE("inferSymptomNative: llama_decode() failed for initial prompt.");
        llama_batch_free(batch);
        return env->NewStringUTF("Error: Engine failed to decode prompt.");
    }

    // Initialize Sampler
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler * smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(50));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.8f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(42)); // Seed 42

    std::stringstream result_ss;
    llama_token new_token_id;
    int max_tokens = (is_diagnosis_mode) ? 500 : 150; // Chat mode doesn't need huge outputs

    for (int i = 0; i < max_tokens; i++) {
        new_token_id = llama_sampler_sample(smpl, g_ctx, -1);
        llama_sampler_accept(smpl, new_token_id);

        if (llama_vocab_is_eog(vocab, new_token_id)) {
            break;
        }

        char buf[32];
        int n = llama_token_to_piece(vocab, new_token_id, buf, sizeof(buf), 0, true);
        if (n > 0 && n < (int)sizeof(buf)) {
            buf[n] = '\0';
            result_ss << buf;
        }

        batch.n_tokens = 1;
        batch.token[0] = new_token_id;
        batch.pos[0] = tokens.size() + i;
        batch.seq_id[0][0] = 0;
        batch.n_seq_id[0] = 1;
        batch.logits[0] = true;

        if (llama_decode(g_ctx, batch) != 0) {
            LOGE("inferSymptomNative: llama_decode() failed during generation loop.");
            break;
        }
    }

    llama_sampler_free(smpl);
    llama_batch_free(batch);

    std::string generated_text = result_ss.str();
    
    // Clear context so next query doesn't append infinitely (we aren't storing KV history cleanly here for simplicity)
    llama_memory_clear(llama_get_memory(g_ctx), true);

    LOGI("inferSymptomNative: Inference complete. Length: %zu", generated_text.length());
    return env->NewStringUTF(generated_text.c_str());
#endif
}

JNIEXPORT void JNICALL
Java_com_pocketswasth_pocket_1swasth_MainActivity_unloadModelNative(
        JNIEnv *env, jobject thiz) {
#ifdef __arm__
    // Do nothing on 32-bit
#else
    if (g_ctx) {
        llama_free(g_ctx);
        g_ctx = nullptr;
    }
    if (g_model) {
        llama_free_model(g_model);
        g_model = nullptr;
    }
    llama_backend_free();
#endif
    g_model_loaded = false;
    LOGI("unloadModelNative: GGUF model and backend safely freed.");
}

}
