## files

- **server.lua** -- the server -- hosts and simulates gameplay, sends updates to all clients
- **client.lua** -- the client -- connects to a server to show its gameplay, listens for input to update the player, draws gameplay
- **common.lua** -- code shared between the client and server -- the client updates some gameplay locally for a smoother experience, the code for that is in this file so it can be shared between the client and the server
- **combined.lua** -- run both the client and the server in the same game -- makes testing easier
