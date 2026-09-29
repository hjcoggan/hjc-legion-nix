{ ... }:

{
  home.username = "heath";
  home.homeDirectory = "/home/heath";

  # Niri config adapted from https://github.com/CachyOS/cachyos-niri-settings
  xdg.configFile."niri".source = ./niri;

  # Automount removable drives in niri (Plasma does this on its own)
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  # OpenCode: local coding agent using Ollama models (see modules/llm.nix). Switch with /models.
  programs.opencode = {
    enable = true;
    settings = {
      model = "ollama/gpt-oss:20b";
      provider.ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://127.0.0.1:11434/v1";
        models."gpt-oss:20b".name = "gpt-oss 20B (fast, fits in VRAM)";
        models."qwen3.6:35b-a3b".name = "Qwen3.6 35B-A3B (stronger, partly on CPU)";
      };
      autoupdate = false;
    };
  };

  home.stateVersion = "25.11";
}
