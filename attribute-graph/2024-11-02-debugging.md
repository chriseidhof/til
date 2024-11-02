# Attribute Graph Debugging

Tried to follow Rens's instructions, didn't work. Did discover a few LLDB tricks:

> (lldb) register read x0 # prints the x0 register (e.g. C++'s this)
> (lldb) image list | grep AttributeGraph # base address
> (lldb) image lookup -rn AG::Graph::print\(\) # address of the print function

For my purposes, this seems very helpful: [AGDebugKit](https://github.com/OpenSwiftUIProject/AGDebugKit)

To generate a PDF from the generated dot file, use `dot -Tpdf $input -o out.pdf`
