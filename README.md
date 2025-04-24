# Calculate spin structures on low dimensional flat manifolds

Use maxima, bash scripts, CARAT and GAP to calculate flat manifolds with or without spin structure of dimension up to 6.

## 2-groups

The crucial step is te determine spin structures on flat manifolds with 2-group holonomy.

### Maxima

```maxima
load("qdata.mac");
```

```maxima
load("qcode.mac");
```

```maxima
run();
```

```maxima
print_to_file("qdata.g", A);
```


### GAP

```gap
Read("qcode.g");
```

```gap
q:=ReadAsFunction("qdata.g")();;
```

With `true` the functions is verbose:
```gap
FillQData(g, true);
```

Make sure to create a destination folder, `/tmp/qdata` in this example.
```gap
WriteQData(q, "/tmp/qdata");
```

### Shell

Conditions:

    1. Make sure you have access to `bash` shell.
    1. In this example CARAT is located in `/usr/local/src/gap-4.14.0/pkg/caratinterface/bin/x86_64-pc-linux-gnu-default64-kv9`. Change `carat-env.sh` accordingly.

```bash
./qtoz.sh /tmp/qdata
```

```bash
./extensions.sh /tmp/qdata
```

```bash
./generate-data.sh /tmp/qdata | tee snames.g
```

### GAP

```gap
Read("acode.g");
```

```gap
s := ReadAsFunction("snames.g")();;
ReadAffData(s, "/tmp/qdata");
```

The `true` flag is for verbosity and can be ommited:
```gap
CheckSpinStructures(s, q, true);
```

Optional: write result to `sdata.g` file:
```gap
str := String(s);;
RemoveCharacters(str, " \r\t\n");
PrintTo("sdata.g", "return ", str, ";\n");
```
