# Calculate spin structures on low dimensional flat manifolds

Calculate flat manifolds with or without spin structure in dimensions up to 6.

## Prerequisities

1. The following tools are used to obtain the results:

    - bash: we use some scripting
    - [maxima](https://maxima.sourceforge.io/): needed to work with Clifford algebras
    - [GAP](https://www.gap-system.org/)
    - [CARAT](https://lbfm-rwth.github.io/carat/), available also as GAP package
    - [HAPCryst](https://gap-packages.github.io/hapcryst/) GAP package
2. Change data in `carat-env.sh` to reflect the GAP and CARAT setup. Import the variables to the session:

    ```bash
    source carat-env.sh
    ```

## Step 0: Generating Bieberbach groups

Here is an example way of generating low dimensional, i.e. up to dimension 6, Bieberbach groups.

**IMPORTANT:** The results of the following calculations have been saved in the files `qdata.g` and `bieberbach.g`, which are the part of this repository. This step can be skipped.

**Remark:** In the following, the folder `/tmp/data` is used to store all calculations. Obviously, it can be changed to anything else.

**Remark:** This section uses only shell's commands, which should be invoked from within the root folder of the source tree.

**Remark:** The `qtoz.sh` and `extensions.sh` scripts accept an option `-j number_of_jobs`, which makes them run in parallel. This will be noted in brackets, e.g. `[ -j 16 ]`.

1. Copy CARAT files holding representatives of $\mathbb Q$-classes and their presentations:

    ```bash
    $ ./qcopy /tmp/data
    ```
1. Generate representatives of $\mathbb Z$-classes:

    ```bash
    $ ./qtoz.sh [ -j 16 ] /tmp/data
    ```
    **Note:** We are interesting in generating torsion-free crystallographic groupsm we can filter those $\mathbb Q$-classes, for which there exists an element without eigenvalue $1$. This id the default behaviour of the `qtoz.sh` script. It is slower at this stage, but saves time at the next one. For generating all $\mathbb Z$-classes, use the `-a` switch:

    ```bash
    $ ./qtoz.sh -a [ -j 16 ] /tmp/data
    ```
1. Generate torsion-free extensions for every representative of the $\mathbb Z$-classes:

    ```bash
    $ ./extensions.sh [ -j 16 ] /tmp/data
    ```
1. Write names and generators of low dimensional Bieberbach groups to `bieberbach.g` file:

    ```bash
    $ gap -b -c 'Read("names.g"); b:=ReadAffCaratDir("/tmp/data"); str:=String(b); RemoveCharacters(str, " \r\t\n"); PrintTo("bieberbach.g", "return ", str, ";" ); quit;'
    ```

1. We will also need the data of $\mathbb Q$-classes in GAP:

    ```bash
    $ gap -b -c 'Read("names.g"); q:=ReadQCaratDir("/tmp/data"); str:=String(q); RemoveCharacters(str, " \r\t\n"); PrintTo("qdata.g", "return ", str, ";" ); quit;'
    ```
**Note:** One can check the results by counting number of generated files. Data is taken from [CARAT doc](https://lbfm-rwth.github.io/carat/doc/) website:

```bash
$ ./count.sh -aqz /tmp/data
Number of Q classes: 8329    # total number of Q-classes
Number of Z classes: 44691   # number of Z-classes without -a switch for qtoz.sh; with this switch the result should be 92185
Number of Aff classes: 39893 # total number of low dimensional Bieberbach groups
```

## Step 1: Preparing data for Bieberbach groups

**Remark:** In this step we are working with GAP.

**Remark:** Whenever we say about a Bieberbach group $\Gamma$, it fits the following short exact sequence:  
$$ 0  \longrightarrow \mathbb{Z}^n \longrightarrow \Gamma \stackrel{\pi}{\longrightarrow} G \longrightarrow 1$$

1. Read the $\mathbb Q$ and $\text{Aff}$ data:

    ```bash
    gap> qdata := ReadAsFunction( "qdata.g" )();;
    gap> adata := ReadAsFunction( "bieberbach.g" )();;
    ```

1. Load the `code.g` file:

    ```gap
    gap> Read( "code.g" );
    ```
1. The `ParseAffData` function generates basic information for Bieberbach groups from `adata`, which are needed for further calculations. For a group $\Gamma$ these include:

    - orientability
    - $\mathbb Q$-class of $G$ (from `qdata`)
    - the CARAT name of the subgroup $\pi^{-1}(\text{Syl}_2(G))$ (the preimage of the Sylow $2$-subgroup of $G$)
    - the dimension of $H^1(\Gamma, \mathbb{F}_2)$

    Note that if $\Gamma$ is not orientable, the rest of the info is not needed, since $\Gamma$ is not spin. For the sake of time of the execution, the default behaviour of the function is as follows:

    a) determine orientability of $\Gamma$  
    b) if $\Gamma$ is orientable, calculate $\mathbb Q$-class of $G$ and $\pi^{-1}(\text{Syl}_2(G))$

    Here are the options to run the function:

    - the default (minimal set of information):

        ```gap
        gap> ParseAffData( qdata, adata );
        ```
    - calculate info for all groups:

        ```gap
        gap> ParseAffData( qdata, adata : all );
        ```
    - calculate the first cohomology

        ```gap
        gap> ParseAffData( qdata, adata : cohomology );
        ```
    - calculate all information:

        ```gap
        gap> ParseAffData( qdata, adata : all, cohomology);
        ```
## Step 2: Lifts of certain holonomy groups to $\text{Spin}(n)$

The crucial step is the determination of spin structures on flat manifolds with 2-group holonomy. We are interested in:

- orientable, in our case those which lie in $\text{SL}(n,\mathbb{Q})$, groups
- of dimension greater than $3$ - up to this dimension all manifolds are spin 

1. Orientable Bieberbach groups with $2$-group holonomy $\mathbb{Q}$-classes of their holonomy groups can be obtained by:

    ```gap
    gap> oq2data := SSortedList( Filtered( adata, x->x.orientable and x.qdata.dim>3 and x.qdata.size>1 and x.qdata.size = 2^Log2Int(x.qdata.size) ), x->x.qdata );;
    ```

    We get 63 classes to work with further.

1. Now comes the part where we look for lifts of generators of the group. This is done by hand (we can use methods from the article). The data is stored in `sdata.mac` file.

1. In order to work with Clifford algebras, we use Maxima. The `run` function involves:

    a) checking if the groups lie in $O(n,\mathbb{Z})$ (almost all are)  
    b) checking whether we generated inverses of elements of $\text{Spin}(n)$  
    c) checking whether the elements of $\text{Spin}(n)$ are in fact lifts of the generators  
    d) generating the presentation of lift of the holonomy groups

    The following should be run in Maxima:

    ```maxima
    (%i1) load( "sdata.mac" );
    (%i2) load( "scode.mac" );
    (%i3) run(false); /* true to use verbose mode */
    (%i4) print_to_file( "sdata.g", A );
    ```

    Let us be more precise about the presentation. If $\lambda \colon \text{Spin}(n) \to O(n)$ is the covering map, $G$ is as above, then its lift to spin is a central extension  
    $$ 1 \longrightarrow \{ \pm 1 \} \longrightarrow \widetilde G \stackrel{\lambda}{\longrightarrow} G \longrightarrow 1.$$  
    Hence in the presentation of $\widetilde G$ we get a central element $c$ of order $2$. The only nontrivial calculations involve lifting presentation of $G$, i.e. if $w$ is a relator in $G$, $\widetilde w$ - its lift to $\widetilde G$, then either $\widetilde w = 1$ or $\widetilde w = c$. This is a task of the step d).

## Step 3: Spin structures for low dimensional Bieberbach groups

1. Having proper data from Maxima, we can use GAP to generate the holonomy groups and their lifts to $\text{Spin}(n)$. The `FillSpinQData` function, called by `FillSpinAffData`, will check for consistence of the data generated by Maxima with the data so far calculated by GAP.

    ```gap
    gap> sdata := ReadAsFunction( "sdata.g" )();;
    gap> FillSpinAffData( adata, oq2data, sdata );
    ```
