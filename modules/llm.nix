{ pkgs, ... }:

# Local LLM for coding (LÖVE / Godot) on the RX 9070 XT via Ollama.
#   qwen3.6:35b-a3b  ~23 GB, mixture-of-experts (~3B active per token): too big for the 16 GB of
#                    VRAM alone, so part of it runs from system RAM.
# The model unloads after 5 idle minutes, freeing the GPU for games and the Godot editor.
# Chat:  ollama run qwen3.6:35b-a3b        Agent:  opencode (configured in home/default.nix)
{
  services.ollama = {
    enable = true;
    # Vulkan is the most reliable backend on RDNA4. To try ROCm instead: pkgs.ollama-rocm
    package = pkgs.ollama-vulkan;
    loadModels = [ "qwen3.6:35b-a3b" ]; # pulled automatically after a rebuild (~23 GB)
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768"; # default is only 4096, far too small for coding
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves context memory; needs flash attention
      OLLAMA_KEEP_ALIVE = "5m";
    };
  };
}
