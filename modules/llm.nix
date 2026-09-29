{ pkgs, ... }:

# Local LLMs for coding (LÖVE / Godot) on the RX 9070 XT via Ollama.
#   gpt-oss:20b      ~14 GB, fits fully in the 16 GB of VRAM: fast, the safe default.
#   qwen3.6:35b-a3b  ~23 GB, mixture-of-experts (~3B active per token): too big for VRAM alone,
#                    so part of it runs from system RAM. Slower, but the stronger coder on paper.
# Models unload after 5 idle minutes, freeing the GPU for games and the Godot editor.
# Chat:  ollama run <model>        Agent:  opencode (configured in home/default.nix)
{
  services.ollama = {
    enable = true;
    # Vulkan is the most reliable backend on RDNA4. To try ROCm instead: pkgs.ollama-rocm
    package = pkgs.ollama-vulkan;
    loadModels = [ "gpt-oss:20b" "qwen3.6:35b-a3b" ]; # pulled automatically after a rebuild (~37 GB total)
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768"; # default is only 4096, far too small for coding
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves context memory; needs flash attention
      OLLAMA_KEEP_ALIVE = "5m";
    };
  };
}
