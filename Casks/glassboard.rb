cask "glassboard" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/luked7/glassboard/releases/download/v#{version}/Glassboard.zip"
  name "Glassboard"
  desc "A fast, private visual clipboard history"
  homepage "https://github.com/luked7/glassboard"

  depends_on macos: ">= :ventura"

  app "Glassboard.app"
end
