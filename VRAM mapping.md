# VRAM mapping
A concept for the VRAM mapping for the game.  
Not finalized, anyting and everything can change.  
Will be filled in more later, when I start getting things into place.

### Tilesets:
| block 0 `($8000)` | block 1 `($8800)` | block 2 `($9000)`  |
|-------------------|-------------------|--------------------|
| `($??)` Player    | `($20)` Platform  | `($??)` Tower      |
| `($??)` Enemies   | `($??)` Enemies   | `($??)` Background |
| `($??)` Bullets   |                   | `($??)` HUD        |
| `($??)` Objects   |                   |                    |
| `($??)` **Total** | `($??)` **Total** | `($??)` **Total**  |

### Tilemaps:
| screen 0 `($9800)`  | screen 1 `($9C00)`   |
|---------------------|----------------------|
| `(32x32)` Tower     | `(32x18)` Background |
|                     | `(32x04)` Platform   |
|                     | `(32x03)` GUI        |
| `(32x32)` **Total** | `(32x25)` **Total**  |
