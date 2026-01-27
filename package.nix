{ stdenv, fetchurl, ostree, autoPatchelfHook, webkitgtk_4_1, buildFHSEnv, appimageTools, icu, ... }:

let
  pname = "hytale-launcher";
  version = "release/2026.01.24-997c2cb";

  hytale-launcher-unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      #TODO: find out how to not only get a specific version, if possible
      url = "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.flatpak";
      hash = "sha256-14Yd4hMipAtdzr8msHugfqJHtr8slLBd1/shX4qJ9WM=";
    };

    nativeBuildInputs = [
      ostree
      autoPatchelfHook
    ];

    buildInputs = [
      webkitgtk_4_1
    ];

    unpackPhase = ''
      runHook preUnpack

      ostree --repo=repo init --mode=archive-z2
      ostree --repo=repo static-delta apply-offline $src

      # black magic to get commit hash
      commit="$(echo repo/objects/*/*.commit)"
      commit="''${commit#repo/objects/}"
      commit="''${commit%.commit}"
      commit="''${commit/\//}" # replaces "/" with ""

      ostree --repo=repo checkout -U $commit extracted
      
      rm -r repo
      mv extracted/* .
      rmdir extracted

      runHook postUnpack
    '';

    # patchPhase = ''
    #   runHook prePatch
    #   runHook postPatch
    # '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      install -Dm755 files/bin/hytale-launcher $out/bin/hytale-launcher
      install -Dm755 files/bin/hytale-launcher-wrapper $out/bin/hytale-launcher-wrapper # flatpak auto-update wrapper, NOT nix wrapper
      install -Dm644 files/share/applications/com.hypixel.HytaleLauncher.desktop $out/share/applications/com.hypixel.HytaleLauncher.desktop
      install -Dm644 files/share/metainfo/com.hypixel.HytaleLauncher.metainfo.xml $out/share/metainfo/com.hypixel.HytaleLauncher.metainfo.xml
      install -Dm644 files/share/icons/hicolor/256x256/apps/com.hypixel.HytaleLauncher.png $out/share/icons/hicolor/256x256/apps/com.hypixel.HytaleLauncher.png
      install -Dm644 files/share/icons/hicolor/128x128/apps/com.hypixel.HytaleLauncher.png $out/share/icons/hicolor/128x128/apps/com.hypixel.HytaleLauncher.png
      install -Dm644 files/share/icons/hicolor/64x64/apps/com.hypixel.HytaleLauncher.png $out/share/icons/hicolor/64x64/apps/com.hypixel.HytaleLauncher.png
      install -Dm644 files/share/icons/hicolor/48x48/apps/com.hypixel.HytaleLauncher.png $out/share/icons/hicolor/48x48/apps/com.hypixel.HytaleLauncher.png
      install -Dm644 files/share/icons/hicolor/32x32/apps/com.hypixel.HytaleLauncher.png $out/share/icons/hicolor/32x32/apps/com.hypixel.HytaleLauncher.png
      runHook postInstall
    '';

    desktopItems = [
      "files/share/applications/com.hypixel.HytaleLauncher.desktop"
    ];
  };
in buildFHSEnv (appimageTools.defaultFhsEnvArgs // {
  inherit pname version;

  targetPkgs = (pkgs: with pkgs; [
    hytale-launcher-unwrapped
    icu
  ]);

  runScript = ''
    ${hytale-launcher-unwrapped}/bin/hytale-launcher
  '';

  extraInstallCommands = ''
    mkdir -p $out/share

    install -Dm644 ${hytale-launcher-unwrapped}/share/applications/com.hypixel.HytaleLauncher.desktop $out/share/applications/com.hypixel.HytaleLauncher.desktop
    sed -i 's/hytale-launcher-wrapper/hytale-launcher/g' $out/share/applications/com.hypixel.HytaleLauncher.desktop

    ln -s ${hytale-launcher-unwrapped}/share/metainfo $out/share/metainfo
    ln -s ${hytale-launcher-unwrapped}/share/icons $out/share/icons
  '';
})
