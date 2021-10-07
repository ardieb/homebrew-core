class HarmonyOne < Formula
  desc "CLI tool to interact with the Harmony Blockchain"
  homepage "https://docs.harmony.one/"
  url "https://github.com/harmony-one/harmony/archive/refs/tags/v4.3.0.tar.gz"
  head "https://github.com/harmony-one/harmony.git"
  sha256 "d463cd60973509f2a7e906582a09a7cd21cf3638b956f164c63e0536a2063367"
  license "LGPL-3.0-or-later"

  depends_on "go" => :build

  depends_on "gmp"
  depends_on "openssl@3"

  # keep resources updated according to the changelog on new release tag:
  # https://github.com/harmony-one/harmony/releases/tag/v#{version}
  resource "go-sdk" do
    url "https://github.com/harmony-one/go-sdk.git",
        revision: "857736c1c51091d86049c3860604830903b046aa"
  end

  resource "bls" do
    url "https://github.com/harmony-one/bls.git",
        revision: "2b7e49894c0f15f5c40cf74046505b7f74946e52"
  end

  resource "mcl" do
    url "https://github.com/harmony-one/mcl.git",
        revision: "99e9aa76e84415e753956c618cbc662b2f373df1"
  end

  def install
    # See https://github.com/golang/go/issues/26487
    ENV.O0 if OS.linux?

    ENV["GOPATH"] = buildpath

    dir = buildpath/"src/github.com/harmony-one/harmony"
    dir.install buildpath.children

    %w[mcl bls go-sdk].each do |r|
      temp_dir = buildpath/"src/github.com/harmony-one/#{r}"

      resource(r).stage do
        mv pwd, temp_dir
        system "make", "BLS_SWAP_G=1" if r == "bls"
      end
    end

    cd buildpath/"src/github.com/harmony-one/go-sdk" do
      system "make"

      lib.install Dir["../bls/lib/*.{dylib,so}"]
      lib.install Dir["../mcl/lib/*.{dylib,so}"]
      bin.install "dist/hmy"

    end
  end

  livecheck do 
    url "https://github.com/harmony-one/harmony/releases"
    strategy :page_match do |page|
      match = page.match(/href=\/harmony-one\/harmony\/releases\/tag\/v(\d+\.\d+\.\d+)/)
      "#{match[1]}"
    end
  end

  test do
    assert_match "Manage your local keys", shell_output("hmy keys").strip
    assert_match "Harmony (C) 2020. hmy", shell_output("hmy version 2>&1").strip
  end
end