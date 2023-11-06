#include <node.h>
#include <vector>

using namespace v8;

void getPlaylists(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  Local<Array> playlists = Array::New(isolate, 0);
  args.GetReturnValue().Set(playlists);
}

void getPlaylistItems(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  Local<Array> playlists = Array::New(isolate, 0);
  args.GetReturnValue().Set(playlists);
}

void getAllTracks(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();
  Local<Array> tracks = Array::New(isolate, 0);
  args.GetReturnValue().Set(tracks);
}

void Initialize(Local<Object> exports) {
  NODE_SET_METHOD(exports, "getPlaylists", getPlaylists);
  NODE_SET_METHOD(exports, "getPlaylistItems", getPlaylistItems);
  NODE_SET_METHOD(exports, "getAllTracks", getAllTracks);
}

NODE_MODULE(NODE_GYP_MODULE_NAME, Initialize)
