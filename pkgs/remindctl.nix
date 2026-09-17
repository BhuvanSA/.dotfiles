{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "remindctl";
  version = "0.3.4";

  src = fetchurl {
    url = "https://github.com/openclaw/remindctl/releases/download/v${finalAttrs.version}/remindctl-macos.zip";
    hash = "sha256-tqEfSOMf59lL6HyDnho7ZM0kokY+OmjVYyzjuvB+QKE=";
  };

  nativeBuildInputs = [ unzip ];

  # The zip holds a single bare `remindctl` binary, no top-level directory.
  sourceRoot = ".";

  # Prebuilt, signed universal binary — stripping would invalidate the signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 remindctl $out/bin/remindctl
    runHook postInstall
  '';

  meta = {
    description = "Fast CLI for Apple Reminders";
    homepage = "https://github.com/openclaw/remindctl";
    license = lib.licenses.mit;
    mainProgram = "remindctl";
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
