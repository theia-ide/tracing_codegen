# Tracing Codegen

An example project, demonstrating how to generate trace information in an Xtext code generator.

## Why Tracing

To allow going back from generated code to the original source, for instance during debugging, we need to keep track of a mapping between the orginal source code and the generated text files. While such mappings are also known as source maps, we call them trace models in Xtext.

So far such trace models have only been created for Xbase expressions, but general support has been lacking. In Xtext 2.12 we [introduced a new API](https://github.com/eclipse/xtext-core/pull/288/files) to allow creating traces in arbitrary code generators.

## Try the Examples

This repository contains two examples, one available as Eclipse plug-in and the other one as a web application.

### Eclipse Plug-in

 * Import the projects from the `eclipse` directory into your workspace.
 * Create and run an _Eclipse Application_ run configuration.
 * Create a plain project and a file with `mydsl` extension.
 * The output is generated to the `src-gen` subdirectory of your project.
 * Use the _Open Generated File_ and _Open Source File_ context menu actions to navigate between the DSL and the generated C code.

 Try the following DSL file content:

 ```
 class Person {
    name: string
    bag: Bag
    getCash(): number {
        bag.wallet.cash
    }
}

class Bag {
    wallet: Wallet
    phone: Phone
}

class Wallet {
	cash: number
}

class Phone {
	model: string
	price: number
	peek(p: Person): number {
		p.getCash()
	}
}
```

### Web Application

 * Point your terminal to the `web` directory and run `./gradlew jettyRun`
 * Open `http://localhost:8080/` in a web browser that supports [source maps](https://developer.mozilla.org/en-US/docs/Tools/Debugger/How_to/Use_a_source_map), e.g. Firefox or Chrome.
 * You should see a message dialog with the result value after clicking the _Run_ button.
 * Open `index.html` in the developer tools of your browser and set a breakpoint at the line `calc.execute();`
 * Click the _Run_ button and step into the `execute()` function.
 * Now you should be able to step through the DSL code.

In order to import the project in Eclipse, install [Buildship](https://projects.eclipse.org/projects/tools.buildship/downloads) and use the Gradle import wizard.

## How To

To generate traces along with the actual text, we need to not only provide the text to generate but also location information about the orginal source code. To keep the code generator as readable as possible the offered API allows for very dense style.

To use it you need to do the following steps.

### Create An Extension Provider for Your EMF model

We want to trace all feature accesses, so we cannot directly call the getters on the EMF model, but need to wrap that access in special accessors. Xtext provides an annotation that automatically generates tracing accessors. All you need to do is create a class, annotate it with `TracedAccessors` and parameterize it with the factory interfaces from your EMF models:
```xtend
@TracedAccessors(MyDslFactory)
class MyDslTraceExtensions {
  // additional utilities could go here
}
```

### Inject The Extensions Class In Your Generator

Next up you go to your code generator class (e.g. `MyDslGenerator`) and let guice inject an instance of the created class into it:

```xtend
class MyDslGenerator extends AbstractGenerator {
	
	@Inject extension MyDslTraceExtensions
	
	... more code here

}
```

### Generate Traced Files

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

### Calling @Traced Methods

If you annotate a method that has at least one parameter of type EObject with `@Traced`, the method will use the first parameter of type EObject for tracing. So as you see above the method `generateClass` is called for every `ClassDeclaration`.

Since `generateClass` is annotated with @Trace, the resulting string will be mapped to the source location of the given ClassDeclaration.
```xtend 
	@Traced def generateClass(ClassDeclaration it) '''
		class «_name» {
			«FOR m : members»
				«generateMember(m)»
			«ENDFOR»
		}
	'''
```

### Fine Grained Tracing

To trace even more fine grained output, for instance tracing the name symbol in the generated class back to the name symbol from the source, you can use the generated accessor extensions from `MyDslTraceExtensions`. It will provide a tracing extension method for every accessor in your EMF model. Those methods start with an `_` appended with the feature name.

See how the we use `_name` instead of the usual `name` in `generateClass` above.

The simple trace accessors only exists for simple types with a good `toString` representation (String, Boolean, Integer, boolean, int). An accessor that accepts a lambda is created for all features. For example in the following we use `_type[type.name]` to trace the type name to the `type` feature of a property.
```xtend
	@Traced def dispatch generateMember(Property it) '''
		«_name» : «_type[type.name]»
	'''
```

## Concepts

The tracing API is based around a tree model composed of `IGeneratorNode`. Out of the box the following node kinds are supported:

### CompositeGeneratorNode
A `CompositeGeneratorNode` can contain multiple child nodes.

### TraceNode
A `TraceNode` is a composite node that in addition contains source information.

### IndentNode
An `IndentNode` is a composite node that indicates that all its children are indented.

### TextNode
A `TextNode` is a leaf node that contains text to be emitted to the generated file.

### NewLineNode
A `NewLineNode` is a leaf node that indicates a line break.

### TemplateNode
A `TemplateNode` is able to wrap an Xtend Template String, which in turn can contain `IGeneratorNode` instances in evaluation parts.
