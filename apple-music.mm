#import <Foundation/Foundation.h>
#import <iTunesLibrary/ITLibrary.h>
#import <iTunesLibrary/ITLibPlaylist.h>
#import <iTunesLibrary/ITLibMediaItem.h>
#import <iTunesLibrary/ITLibArtist.h>
#include <node.h>
#include <uv.h>

namespace appleMusic {

using v8::FunctionCallbackInfo;
using v8::Isolate;
using v8::Local;
using v8::Array;
using v8::Object;
using v8::String;
using v8::Value;

char const *emptyString = "";

// Write me a new getPlayLists function which only returns the playlists; those playlists has at least a name and a ID
void getPlaylists(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate(); // Setup for Javascript Connection
    Local<v8::Context> context = isolate->GetCurrentContext(); // Retrieve the current context

    Local<Array> jsPlaylistsArr = Array::New(isolate); // Create Array for Javascript v8 engine

    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error]; // Connect to iTunes / Music Library

    if (library) {
        NSArray *playlists = library.allPlaylists;
        int size = [playlists count];

        for (int i = 0; i < size; i++) {
            ITLibPlaylist *playlist = playlists[i];
            //(playlist.distinguishedKind == ITLibDistinguishedPlaylistKindMusic ||
            if (playlist.kind == ITLibPlaylistKindFolder || playlist.kind == ITLibPlaylistKindRegular) {
                NSString *name = [playlist name];
                const char *nameInC = [name UTF8String];

                int itemCount = [playlist.items count];

                Local<Object> jsPlaylist = Object::New(isolate);
                jsPlaylist->Set(context, String::NewFromUtf8(isolate, "name").ToLocalChecked(), String::NewFromUtf8(isolate, nameInC).ToLocalChecked()).FromJust();

                // Expose ID as string since playlist ID may be too large for JavaScript numbers
                NSNumber *persistentID = playlist.persistentID;
                NSNumber *parentID = playlist.parentID;

                double persistentIDDouble = [persistentID doubleValue];
                double parentIDDouble = [parentID doubleValue];

                jsPlaylist->Set(context, String::NewFromUtf8(isolate, "persistentID").ToLocalChecked(), v8::Number::New(isolate, persistentIDDouble)).FromJust();
                jsPlaylist->Set(context, String::NewFromUtf8(isolate, "parentID").ToLocalChecked(), v8::Number::New(isolate, parentIDDouble)).FromJust();


                jsPlaylist->Set(context, String::NewFromUtf8(isolate, "itemCount").ToLocalChecked(), v8::Integer::New(isolate, itemCount)).FromJust();

                jsPlaylistsArr->Set(context, i, jsPlaylist).FromJust();

            }
        }

        args.GetReturnValue().Set(jsPlaylistsArr);
    }
}

// Then write a new function which returns the items of a playlist by playlist ID
void getPlaylistItems(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate(); // Setup for Javascript Connection
    Local<v8::Context> context = isolate->GetCurrentContext(); // Retrieve the current context

    // Get playlist ID from function arguments
    Local<String> playlistIDStr = args[0].As<String>();
    v8::String::Utf8Value playlistIDStrUtf8(isolate, playlistIDStr);
    // playlistId is a string, convert to double
    NSString* playlistStrInC = [NSString stringWithUTF8String:*playlistIDStrUtf8];
    double playlistID = [playlistStrInC doubleValue];

    int limit = args[1]->IntegerValue(context).ToChecked();

    // log playListID to javascript console
    // Local<String> jsPlaylistID = String::NewFromUtf8(isolate, "PlaylistID: ").ToLocalChecked();
    // Local<String> jsPlaylistIDConcat = String::Concat(isolate, jsPlaylistID, playlistIDStr);
    // Local<v8::Object> consoleObj = context->Global()->Get(context, String::NewFromUtf8(isolate, "console").ToLocalChecked()).ToLocalChecked().As<v8::Object>();
    // Local<v8::Function> logFunc = consoleObj->Get(context, String::NewFromUtf8(isolate, "log").ToLocalChecked()).ToLocalChecked().As<v8::Function>();
    // Local<Value> logArgs[] = { jsPlaylistIDConcat };
    // logFunc->Call(context, consoleObj, 1, logArgs).ToLocalChecked();

    Local<Array> jsItemsArr = Array::New(isolate); // Create Array for Javascript v8 engine

    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error]; // Connect to iTunes / Music Library

    if (library) {
        NSArray *playlists = library.allPlaylists;

        // loop through all playlists and find the playlist with the correct playlistID
        int size = [playlists count];
        ITLibPlaylist *playlist;
        for (int i = 0; i < size; i++) {
            ITLibPlaylist *currentPlaylist = playlists[i];
            NSNumber *persistentID = currentPlaylist.persistentID;
            double persistentIDDouble = [persistentID doubleValue];
            if (persistentIDDouble == playlistID) {
                playlist = currentPlaylist;
                break;
            }
        }

        if (playlist) {
            NSArray *items = playlist.items;
            int itemSize = [items count];
            // add a limit to the itemSize
            if (limit > 0 && limit < itemSize) {
                itemSize = limit;
            }

            for (int j = 0; j < itemSize; j++) {
                ITLibMediaItem *item = items[j];
                NSString *title = [item title];
                NSString *genre = [item genre];
                ITLibArtist *artist = [item artist];
                NSURL *location = [item location];

                // Convert it to c
                const char *titleInC = emptyString;
                const char *artistInC = emptyString;
                const char *filePathInC = emptyString;
                const char *genreInC = emptyString;
                const long bpmInC = [item beatsPerMinute];
                const int ratingInC = [item rating];
                const long totalTimeInC = [item totalTime];
                const int yearInC = [item year];
                const bool isCloudInC = [item isCloud];

                if (isCloudInC) {
                  continue;
                }

                if (title) {
                    titleInC = [title UTF8String];
                }
                if (artist) {
                    NSString *artistNSString = [artist name];
                    if (artistNSString) {
                        artistInC = [artistNSString UTF8String];
                    }
                }
                if (location) {
                    NSString *locationNSString = [location absoluteString];
                    if (locationNSString) {
                        filePathInC = [locationNSString UTF8String];
                    }
                }

                if (genre) {
                    genreInC = [genre UTF8String];
                }

                Local<Object> jsItem = Object::New(isolate); // Create Javascript Object
                jsItem->Set(context, String::NewFromUtf8(isolate, "title").ToLocalChecked(), String::NewFromUtf8(isolate, titleInC).ToLocalChecked()).FromJust(); // Copy data in Javascript Object
                jsItem->Set(context, String::NewFromUtf8(isolate, "genre").ToLocalChecked(), String::NewFromUtf8(isolate, genreInC).ToLocalChecked()).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "artist").ToLocalChecked(), String::NewFromUtf8(isolate, artistInC).ToLocalChecked()).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "filePath").ToLocalChecked(), String::NewFromUtf8(isolate, filePathInC).ToLocalChecked()).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "bpm").ToLocalChecked(), v8::Integer::New(isolate, bpmInC)).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "rating").ToLocalChecked(), v8::Integer::New(isolate, ratingInC)).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "totalTime").ToLocalChecked(), v8::Integer::New(isolate, totalTimeInC)).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "year").ToLocalChecked(), v8::Integer::New(isolate, yearInC)).FromJust();
                jsItem->Set(context, String::NewFromUtf8(isolate, "isCloud").ToLocalChecked(), v8::Boolean::New(isolate, isCloudInC)).FromJust();

                jsItemsArr->Set(context, j, jsItem).FromJust();
            }
            args.GetReturnValue().Set(jsItemsArr);
        }
    }
}

void getAllTracks(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate(); // Setup for Javascript Connection
    Local<v8::Context> context = isolate->GetCurrentContext();
    Local<String> keyTitle = String::NewFromUtf8(isolate, "title").ToLocalChecked();
    Local<String> keyGenre = String::NewFromUtf8(isolate, "genre").ToLocalChecked();
    Local<String> keyArtist = String::NewFromUtf8(isolate, "artist").ToLocalChecked();
    Local<String> keyFilePath = String::NewFromUtf8(isolate, "filePath").ToLocalChecked();
    Local<String> keyBpm = String::NewFromUtf8(isolate, "bpm").ToLocalChecked();
    Local<String> keyRating = String::NewFromUtf8(isolate, "rating").ToLocalChecked();
    Local<String> totalTime = String::NewFromUtf8(isolate, "totalTime").ToLocalChecked();
    Local<String> year = String::NewFromUtf8(isolate, "year").ToLocalChecked();

    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error]; // Connect to iTunes / Music Library
    if (library)
    {
        NSArray *tracks = library.allMediaItems; // Load all Songs with Cocoa / Objective-C
        int size = [tracks count];

        Local<Array> jsSongsArr = Array::New(isolate, size); // Create Array for Javascript v8 engine

        for (int i = 0; i < size; i++) {
            // Reading Data from Cocoa
            ITLibMediaItem *song = tracks[i];
            NSString *title = [song title];
            NSString *genre = [song genre];
            ITLibArtist *artist = [song artist];
            NSURL *location = [song location];
            ITLibMediaItemMediaKind mediaKind = [song mediaKind];
            const bool isCloudInC = [song isCloud];

            if (mediaKind != ITLibMediaItemMediaKindSong) {
              continue;
            }

            if (isCloudInC) {
              continue;
            }

            // Convert it to c
            const char *titleInC = emptyString;
            const char *genreInC = emptyString;
            const char *artistInC = emptyString;
            const char *filePathInC = emptyString;
            const long bpmInC = [song beatsPerMinute];
            const int ratingInC = [song rating];
            const long totalTimeInC = [song totalTime];
            const int yearInC = [song year];

            if (title) {
                titleInC = [title UTF8String];
            }

            if (genre) {
                genreInC = [genre UTF8String];
            }
            if (artist) {
                NSString *artistNSString = [artist name];
                if (artistNSString) {
                    artistInC = [artistNSString UTF8String];
                }
            }
            if (location) {
                NSString *locationNSString = [location absoluteString];
                if (locationNSString) {
                    filePathInC = [locationNSString UTF8String];
                }
            }

            Local<Object> jsSong = Object::New(isolate); // Create Javascript Object
            jsSong->Set(context, keyTitle, String::NewFromUtf8(isolate, titleInC).ToLocalChecked()).FromJust(); // Copy data in Javascript Object
            jsSong->Set(context, keyGenre, String::NewFromUtf8(isolate, genreInC).ToLocalChecked()).FromJust();
            jsSong->Set(context, keyArtist, String::NewFromUtf8(isolate, artistInC).ToLocalChecked()).FromJust();
            jsSong->Set(context, keyFilePath, String::NewFromUtf8(isolate, filePathInC).ToLocalChecked()).FromJust();
            jsSong->Set(context, keyBpm, v8::Integer::New(isolate, bpmInC)).FromJust();
            jsSong->Set(context, keyRating, v8::Integer::New(isolate, ratingInC)).FromJust();
            jsSong->Set(context, totalTime, v8::Integer::New(isolate, totalTimeInC)).FromJust();
            jsSong->Set(context, year, v8::Integer::New(isolate, yearInC)).FromJust();

            jsSongsArr->Set(context, i, jsSong).FromJust(); // Add the Object to Javascript Array
        }
        args.GetReturnValue().Set(jsSongsArr); // Set the return value of the function
    } else { // If error occurs
        args.GetReturnValue().Set(String::NewFromUtf8(isolate, [[error localizedDescription] UTF8String]).ToLocalChecked());
    }
}

// Write me a search function, which can seary on the first argument of the function. This argument is a query string which can be used to search on title or artist for example.
void searchByQuery(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate(); // Setup for Javascript Connection
    Local<v8::Context> context = isolate->GetCurrentContext();

    NSLog(@"hello world");

    v8::Local<v8::String> query = args[0].As<v8::String>();
    //log query to javascript console
    v8::String::Utf8Value queryUtf8Value(isolate, query);
    NSLog(@"query: %@", [NSString stringWithUTF8String:*queryUtf8Value]);

    NSString* queryStr = [NSString stringWithUTF8String:*queryUtf8Value];

    // log query string to javascript console
    NSLog(@"query: %@", queryStr);

    Local<Array> jsItemsArr = Array::New(isolate); // Create Array for Javascript v8 engine

    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error]; // Connect to iTunes / Music Library

    if (library) {
         NSMutableArray *items = [NSMutableArray array];

        // loop through all items in the library
        for (ITLibMediaItem *item in library.allMediaItems) {
            NSString *name = item.title;
            NSString *artistName = item.artist.name;

            // check that name is defined and is a string
            if (name && [name isKindOfClass:[NSString class]]) {
                // check if name contains query string
                if ([name rangeOfString:queryStr options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    // add item to items array
                    [items addObject:item];
                }
            }

            // check if artist is defined and is a string
            if (artistName && [artistName isKindOfClass:[NSString class]]) {
                // check if artist contains query string
                if ([artistName rangeOfString:queryStr options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    // add item to items array
                    [items addObject:item];
                }
            }
        }

        int itemSize = [items count];

        for (int j = 0; j < itemSize; j++) {
            ITLibMediaItem *item = items[j];
            NSString *title = [item title];
            ITLibArtist *artist = [item artist];
            NSURL *location = [item location];

            // Convert it to c
            const char *titleInC = "";
            const char *artistInC = "";
            const char *filePathInC = "";
            const long bpmInC = [item beatsPerMinute];
            const int ratingInC = [item rating];
            const long totalTimeInC = [item totalTime];
            const int yearInC = [item year];

            if (title) {
                titleInC = [title UTF8String];
            }
            if (artist) {
                NSString *artistNSString = [artist name];
                if (artistNSString) {
                    artistInC = [artistNSString UTF8String];
                }
            }
            if (location) {
                NSString *locationNSString = [location absoluteString];
                if (locationNSString) {
                    filePathInC = [locationNSString UTF8String];
                }
            }

            Local<Object> jsItem = Object::New(isolate); // Create Javascript Object
            jsItem->Set(context, String::NewFromUtf8(isolate, "title").ToLocalChecked(), String::NewFromUtf8(isolate, titleInC).ToLocalChecked()).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "artist").ToLocalChecked(), String::NewFromUtf8(isolate, artistInC).ToLocalChecked()).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "filePath").ToLocalChecked(), String::NewFromUtf8(isolate, filePathInC).ToLocalChecked()).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "bpm").ToLocalChecked(), v8::Integer::New(isolate, bpmInC)).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "rating").ToLocalChecked(), v8::Integer::New(isolate, ratingInC)).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "totalTime").ToLocalChecked(), v8::Integer::New(isolate, totalTimeInC)).Check();
            jsItem->Set(context, String::NewFromUtf8(isolate, "year").ToLocalChecked(), v8::Integer::New(isolate, yearInC)).Check();

            jsItemsArr->Set(context, j, jsItem).Check(); // Add the Object to Javascript Array
        }
        args.GetReturnValue().Set(jsItemsArr); // Set the return value of the function
    }
    // return empty array
    args.GetReturnValue().Set(jsItemsArr);
}

void getTotalTrackCount(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate(); // Setup for Javascript Connection

    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error]; // Connect to iTunes / Music Library

    if (library) {
        NSArray *tracks = library.allMediaItems; // Load all songs with Cocoa / Objective-C
        int totalCount = [tracks count];

        args.GetReturnValue().Set(v8::Integer::New(isolate, totalCount));
    } else {
        args.GetReturnValue().Set(v8::Integer::New(isolate, 0)); // Return 0 if there's an error
    }
}

void Initialize(Local<Object> exports) {
  NODE_SET_METHOD(exports, "getPlaylists", getPlaylists);
  NODE_SET_METHOD(exports, "getPlaylistItems", getPlaylistItems);
  NODE_SET_METHOD(exports, "getAllTracks", getAllTracks);
  NODE_SET_METHOD(exports, "searchByQuery", searchByQuery);
  NODE_SET_METHOD(exports, "countAllTracks", getTotalTrackCount);
}

NODE_MODULE(NODE_GYP_MODULE_NAME, Initialize)

}
