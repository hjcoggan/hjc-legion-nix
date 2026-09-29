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

  # OpenCode: local coding agent using Qwen3.6 from Ollama (see modules/llm.nix)
  programs.opencode = {
    enable = true;
    settings = {
      model = "ollama/qwen3.6:35b-a3b";
      provider.ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://127.0.0.1:11434/v1";
        models."qwen3.6:35b-a3b".name = "Qwen3.6 35B-A3B";
      };
      autoupdate = false;
    };
  };

  home.stateVersion = "25.11";
}
