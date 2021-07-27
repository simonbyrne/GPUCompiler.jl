# native target for CPU execution

## target

export NativeCompilerTarget

Base.@kwdef struct NativeCompilerTarget <: AbstractCompilerTarget
    cpu::String=(LLVM.version() < v"8") ? "" : unsafe_string(LLVM.API.LLVMGetHostCPUName())
    features::String=(LLVM.version() < v"8") ? "" : unsafe_string(LLVM.API.LLVMGetHostCPUFeatures())
    always_inline::Bool=false # will mark the job function as always inline
end

llvm_triple(::NativeCompilerTarget) = Sys.MACHINE

function llvm_machine(target::NativeCompilerTarget)
    triple = llvm_triple(target)

    t = Target(triple=triple)

    tm = TargetMachine(t, triple, target.cpu, target.features)
    asm_verbosity!(tm, true)

    return tm
end

function process_entry!(compiler::Compiler{NativeCompilerTarget}, source::FunctionSpec, mod::LLVM.Module, entry::LLVM.Function)
    ctx = context(mod)
    if compiler.target.always_inline
        push!(function_attributes(entry), EnumAttribute("alwaysinline", 0; ctx))
    end
    invoke(process_entry!, Tuple{Compiler, FunctionSpec, LLVM.Module, LLVM.Function}, compiler, source, mod, entry)
end


## compiler

runtime_slug(compiler::Compiler{NativeCompilerTarget}) =
    "native_$(compiler.target.cpu)-$(hash(compiler.target.features))"
