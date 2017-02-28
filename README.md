# Tracing Codegen

An example project, demonstrating how to generate trace information in an Xtext code generator.

# Why Tracing

To allow going back from generated code to the original source, for instance during debugging, we need to keep track of a mapping between the orginal source code and the generated text files. While such mappings are also know as source maps, we call them trace models in Xtext.

So far such trace models have only been created for Xbase expressions, but general support have been lacking. In Xtext 2.12 we [introduce a new API](https://github.com/eclipse/xtext-core/pull/288/files) to allow creating traces in arbitrary code generators.

# How To

To generate traces along with the actual text, we need to not only provide the text to generate but also location information about the orginal source code. To keep the code generator as readable as possible the offered API allows for very dense style.

To use it you need to do the following steps.

## Create An Extension Provider for You EMF model

We want to trace all feature accesses, so we cannot directly call the getters on the EMF model, but need to wrap that access in special accessors. Xtext provides an annotation that automatically generates tracing accessors. All you need to do is create a class, annotate it with `TracedAccessors` and paramterize it with the factory interfaces from your EMF models:
```xtend
@TracedAccessors(MyDslFactory)
class MyDslTraceExtensions {
  // additional utilities could go here
}
```

## Inject The Extensions Class In Your Generator

Next up you go to your code generator class (e.g. `MyDslGenerator`) and let guice inject an instance of the created class into it:

```xtend
class MyDslGenerator extends AbstractGenerator {
	
	@Inject extension MyDslTraceExtensions
	
	... more code here

}
```

## Generate Traced Files

In the main hook of a generator, one gets a `FileSystemAccess` passed in. One of the extensions provided by `MyDslTraceExtensions` is the method `generateTracedFile()`, which you can call like this:

```xtend
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val m = resource.contents.head as Model
		
		fsa.generateTracedFile("foo/Bar.txt", m, '''
			// generated
			«FOR c : m.types»
				«generateClass(c)»
			«ENDFOR»
		''')
	}
```

First we fetch the root EObject from the resource, and then we pass it as the root object for tracing. This means that if we don't add further tracing, the whole content of the generated file will be mapped to the source location of the given root EObject `m`.

During code generation we now add finer trace regions which overlay the broader/outer ones.

## Calling @Traced Methods

If you annotate a method that has at least one parameter of type EObject with `@Traced`, the method will use the first parameter of type EObject for tracing. So as you see above the method `generateClass` is called for every `ClassDeclaration`.

Since `generateClass` is annotated with @Trace the resulting string will be mapped to the source location of the given ClassDeclaration.
```xtend 
	@Traced def generateClass(ClassDeclaration it) '''
		class «_name» {
			«FOR m : members»
				«generateMember(m)»
			«ENDFOR»
		}
	'''
```

## Finegrained Tracing

To trace even more fine grained say, for instance tracing the name symbol in the generated class back to the name symbol from the source, you can use the generated accessor extensions from `MyDslTraceExtensions`. It will provide a tracing extension method for every accessor in your EMF model. Those methods start with an `_` appended with the feature name.

See how the we use `_name` instead of the usual `name` in `generateClass` above.

The simple trace accessors only exists for simple types, with a good `toString` representation (String, Boolean, Integer, boolean, int). But an accessor that accepts a lambda is created for all features. For example in the following we use `_type[name.name]` to trace the type name to the `type` feature of a property.
```xtend
	@Traced def dispatch generateMember(Property it) '''
		«_name» : «_type[name.name]»
	'''
```

# Concepts

The tracing API is based around a tree model comprosed of `IGeneratorNode`. Out of the box the following node kinds are supported:

## CompositeGeneratorNode
A `CompositeGeneratorNode` can contain multiple child nodes.

## TraceNode
A `TraceNode` is a composite node, that in addition contains source information.

## IndentNode
An `IndentNode` is a composite node that indicates that all its children are indented.

## TextNode
A `TextNode` is a leaf node that contains text to be emitted to the generated file.

## NewLineNode
A `NewLineNode` is a leaf node that indicates a line break.

## TemplateNode
A `TemplateNode` is able to wrap an Xtend Template String, which in turn can contain `IGeneratorNode` instances in evaluation parts.
