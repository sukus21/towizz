# VRAM mapping
A concept for the VRAM mapping for the game.  
Not finalized, anyting and everything can change.  
Will be filled in more later, when I start getting things into place.

### Tilesets:
| block 0 `($8000)` | block 1 `($8800)` | block 2 `($9000)`  |
|-------------------|-------------------|--------------------|
| `($??)` Player    | `($20)` Platform  | `($??)` Tower      |
| `($??)` Enemies   | `($08)` HUD       | `($??)` Background |
| `($??)` Bullets   | `($??)` Enemies   |                    |
| `($??)` Objects   |                   |                    |
| `($??)` **Total** | `($28)` **Total** | `($??)` **Total**  |

### Tilemaps:
```
             SCRN0                            SCRN1
______________________________   ______________________________
|              |             |   |              |             |
|  Background  |    Tower    |   |  Background  |    Tower    |
|   (16x18)    |   (16x32)   |   |   (16x18)    |   (16x26)   |
|              |             |   |              |             |
|              |             |   |              |             |
|______________|             |   |______________|             |
|              |             |   | Free (16x8)  |             |
|  Free space  |             |   |______________|_____________|
|   (16x14)    |             |   |         HUD (32x3)         |
|              |             |   |____________________________|
|              |             |   |       Platform (32x3)      |
|______________|_____________|   |____________________________|
```
