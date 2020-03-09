### Notes

Run program as Administrator and open **League Client**. After the **successfully connected** dialog is shown,
please create a new **dummy club** and type on the club's **chatbox**:
```
/?
```

Common commands:
- `/?` or `/help` -> show command list.
- `/? [command]` -> show command guide.
- `/auto` -> turn on/off auto accept match found.
- `/pick [name1] [name2]...` -> auto pick your selected champion (by order) when **Champ Select** starts.
- `/lock` -> turn on/off auto lock after picked.
- `lang [id]` -> change language (the default is based on **League**'s language).

### Example
```
/lang vi
/pick ys yi j4
/auto on
/lock on
```
- 1: change language to Vietnamese.
- 2: set auto pick **Yasuo** > **Master Yi** > **Jarvan IV** (you can type "j4" or "jarvaniv" - champ name without whitespace, [see source](https://github.com/nomi-san/yasuo/blob/eb286e5093a2f2c664eefa79bf5c527864593319/yasharp/src/WashingPole.cs#L268)).
- 3: turn on auto accept match found.
- 4: turn on auto lock after picked.
