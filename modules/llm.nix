{ pkgs, ... }:

# Local LLM for coding (LÖVE / Godot): gpt-oss-20b on the RX 9070 XT via Ollama.
# The model is ~14 GB, so it nearly fills the 16 GB of VRAM. It unloads itself after 5 idle
# minutes, freeing the GPU for games and the Godot editor.
# Chat:  ollama run gpt-oss:20b        Agent:  opencode (configured in home/default.nix)
{
  services.ollama = {
    enable = true;
    # Vulkan is the most reliable backend on RDNA4. To try ROCm instead: pkgs.ollama-rocm
    package = pkgs.ollama-vulkan;
    loadModels = [ "gpt-oss:20b" ]; # pulled automatically after the first rebuild (~14 GB)
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768"; # default is only 4096, far too small for coding
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves context memory; needs flash attention
      OLLAMA_KEEP_ALIVE = "5m";
    };
  };
}
