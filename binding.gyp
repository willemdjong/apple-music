{
  "targets": [
    {
      "target_name": "appleMusic",
      "cflags!": [ "-ObjC++" ],
      "cflags_cc!": [ "-ObjC++" ],
      "libraries": [
        "-framework AppKit",
        "-framework iTunesLibrary"
      ],
       "conditions": [
        ["OS=='mac'", {
          "sources": [ "apple-music.mm" ],
          "defines": [ "PLATFORM_MAC" ]
        }],
        ["OS=='win'", {
          "sources": [ "empty_functions.cpp" ],
          "defines": [ "PLATFORM_WINDOWS" ]
        }]
      ]
    }
  ]
}
