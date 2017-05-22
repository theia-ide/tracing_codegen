package io.typefox.traceexample.eclipse.scoping

import com.google.inject.Inject
import com.google.inject.Provider
import com.google.inject.Singleton
import io.typefox.traceexample.eclipse.myDsl.ClassDeclaration
import io.typefox.traceexample.eclipse.myDsl.MyDslFactory
import java.util.Collections
import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.resource.IDefaultResourceDescriptionStrategy
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.impl.AbstractContainer
import org.eclipse.xtext.resource.impl.DefaultResourceDescription
import org.eclipse.xtext.util.IResourceScopeCache

import static io.typefox.traceexample.eclipse.myDsl.MyDslPackage.Literals.*

@Singleton
class LibraryContainer extends AbstractContainer {

	@Inject Provider<ResourceSet> resourceSetProvider
	
	@Inject IDefaultResourceDescriptionStrategy resourceDescriptionStrategy

	@Inject IResourceScopeCache resourceScopeCache
	
	List<IResourceDescription> descriptions
	
	override getResourceDescriptions() {
		synchronized (this) {
			if (descriptions === null) {
				initLibrary()
			}
		}
		return descriptions
	}
	
	protected def initLibrary() {
		val resourceSet = resourceSetProvider.get
		val resource = resourceSet.createResource(URI::createFileURI('library.mydsl'))
		val factory = MyDslFactory.eINSTANCE
		resource.contents += factory.createModel => [
			types += factory.createClassDeclaration => [
				name = 'number'
			]
			types += factory.createClassDeclaration => [
				name = 'string'
			]
		]
		descriptions = Collections.singletonList(
			new DefaultResourceDescription(resource, resourceDescriptionStrategy, resourceScopeCache)
		)
	}
	
	def URI getURI() {
		resourceDescriptions.head.URI
	}
	
	def ClassDeclaration getType(String name) {
		resourceDescriptions.head.getExportedObjectsByType(CLASS_DECLARATION).findFirst[ descr |
			descr.name.toString == name
		]?.EObjectOrProxy as ClassDeclaration
	}
	
}