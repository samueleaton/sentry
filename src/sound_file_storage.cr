require "baked_file_system"

class SoundFileStorage
  extend BakedFileSystem

  bake_folder "./sounds"
end
