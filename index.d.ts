declare module 'apple-music' {
  export function getPlaylists(): any;
  export function getAllTracks(): any;
  export function getPlaylistItems(playlistId: string, limit?: number): any;
  export function searchByQuery(query: string, limit?: number): any;
  export function countAllTracks(): number;
}
