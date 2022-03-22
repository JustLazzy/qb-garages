# qb-garages

Add this two exports at the bottom of your `qb-radialmenu/client/main.lua`

```lua
exports('AddOption', function(id, data)
    Config.MenuItems[id] = data
end)

exports('RemoveOption', function(id)
    Config.MenuItems[id] = nil
end)
```

Dependencies:

1. [qb-drawtext](https://github.com/IdrisDose/qb-drawtext)

### Credit
Thanks to my boy [Nathan](https://github.com/Nathan-FiveM) 😀😀

Original repo: [qb-garages](https://github.com/qbcore-framework/qb-garages)

Credit to hoangducd / [MojiaGarages](https://github.com/hoangducdt/MojiaGarages)
<BR>
we use some of the code for spawning vehicle

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
