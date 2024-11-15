Sphincter
==============================

What happens when you burn a mouse's brain with a laser?

# How to run the analysis

To run the analysis, install [uv](https://astral.sh/blog/uv) and then run the command `make analysis` from the project root. 

This will install a fresh virtual environment if one doesn't exist already, activate it and install python dependencies and cmdstan, then run the analysis.

Alternatively, you can also run the steps of the analysis individually. To find out which commands to run, check out the [makefile](https://github.com/teddygroves/sphincter/blob/main/Makefile), particularly the target `analysis`.

# How to create a pdf report

First make sure you have installed [quarto](https://https://quarto.org/).

Now run this command from the project root:

```
make docs
```





