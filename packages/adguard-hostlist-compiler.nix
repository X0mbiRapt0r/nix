{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  nodejs,
  stdenv,
  yarnConfigHook,
  yarnInstallHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "adguard-hostlist-compiler";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "AdguardTeam";
    repo = "HostlistCompiler";
    rev = "2da46b1f9ba37c6541e42adb68ccd6872fa72c21";
    hash = "sha256-iAoiDTB6zSPcjHZNyBOzrOPgWYbev6UVRbHWh5vvE28=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-pphYJy36m7S9VzAXtHyMFRCzliRMDaSHyov7haU5kDc=";
  };

  nativeBuildInputs = [
    nodejs
    yarnConfigHook
    yarnInstallHook
  ];

  meta = {
    description = "Compile hosts blocklists from multiple sources";
    homepage = "https://github.com/AdguardTeam/HostlistCompiler";
    license = lib.licenses.gpl3Only;
    mainProgram = "hostlist-compiler";
  };
})
