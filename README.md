# Tracing Codegen

An example project, demonstrating how to generate trace information in an Xtext code generator.

# Background

To allow going back from generated code to the original source, for instance during debugging, we need to keep track of a mapping between the orginal source code and the generated text files. While such mappings are also know as source maps, we call them trace models in Xtext.

So far such trace models have only been created for Xbase expressions, but general support have been lacking. In Xtext 2.12 we introduce a new API to allow creating traces in arbitrary code generators.

# Challenges

To generate traces along with the actual text, we need to not only provide the text to generate but also location information about the orginal source code. In Xtext ASTs are backed up by syntax information, which we can obtain through the `ILocationInFileProvider`interface. However obtaining that explicitly in the code generator on a fine grained level, will make the code generator implementation hardly readable. 

The tracing API provided by Xtext aims at allowing to use very dense style while still allow for extensibility.

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

# API Usages
Creating a tree of generator nodes can be done manually, but it wouldn't read well. So there is additional APIs and even active annotations that can be used to improve the readability of a tracing code generator.

## TraceSugar Extensions

The class `TraceSugar` provides a set of generic extension methods to create generator nodes and add children to them.

## @TracingExtensions

When tracing code for an EMF model, we would need to call generic functions to create a location and the actual value at the same time. With just `TraceSugar` a traced call to e.g. `myEntity.name` would look like this `myEntity.trace(MyPackage.Literals.MY_ENTITY_NAME)` which is sub obtimal. Therefore the active annotation `@TracingExtensions` can be used on a subclass of `TraceSugar` like this:
```
@TracingExtensions(MyDslFactory)
class TraceExtensions {}
```
The annotation will add the supertype `TraceSugar` for you automatically and in addition generate trace enabled accessors for the EObject types of the provided `EcoreFactory`interface.

With that, you can now prepend any accessor with an `_`, which will return a `TraceNode` containing a `TextNode` with the value.

Example: 
```
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val m = resource.contents.head as Model
		
		fsa.generateTracedFile("foo/Bar.txt", m, '''
			// generated
			«FOR c : m.types»
				«generateClass(c)»
			«ENDFOR»
		''')
	}
	
	@Traced def generateClass(ClassDeclaration clazz) '''
		class «clazz._name» {
			«FOR m : clazz.members»
				«generateMember(m)»
			«ENDFOR»
		}
	'''
	
	@Traced def dispatch generateMember(Operation op) '''
		«op._name»(«FOR p : op.parameter»«p._name» : «p._type[name.name]»«ENDFOR») : «op._type[name.name]»
	'''
	
	@Traced def dispatch generateMember(Property op) '''
		«op._name» : «op._type[name.name]»
	'''
```

## @Traced

Additional as you can see in above's example, the annotation `@Traced` can be used on template methods to let the return a `TraceNode`.
