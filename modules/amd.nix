{ pkgs, ... }:

# Ryzen 7 7700 + Radeon RX 9070 XT (RDNA4). Mesa RADV is used by default (best for gaming).
{
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [ "amd_pstate=active" ];

  hardware.amdgpu.initrd.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # LACT: GPU monitoring, fan curves, power limits / undervolt.
  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  environment.systemPackages = with pkgs; [ nvtopPackages.amd vulkan-tools mesa-demos ];
}
