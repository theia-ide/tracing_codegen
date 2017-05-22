/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.generator

import com.google.inject.Inject
import io.typefox.traceexample.myDsl.ClassDeclaration
import io.typefox.traceexample.myDsl.Model
import io.typefox.traceexample.myDsl.MyDslFactory
import io.typefox.traceexample.myDsl.Operation
import io.typefox.traceexample.myDsl.Property
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.generator.trace.node.Traced
import org.eclipse.xtext.generator.trace.node.TracedAccessors

/**
 * A code generator that keeps track of traces between source and generated files.
 * 
 */
class MyDslGenerator extends AbstractGenerator {
	
	@TracedAccessors(MyDslFactory)
	static class MyDslTraceExtensions {}
	
	@Inject extension MyDslTraceExtensions

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val m = resource.contents.head as Model
		
		fsa.generateTracedFile("foo/Bar.txt", m, '''
			// generated
			«FOR c : m.types»
				«generateClass(c)»
			«ENDFOR»
		''')
	}
	
	@Traced def generateClass(ClassDeclaration it) '''
		class «_name» {
			«FOR m : members»
				«generateMember(m)»
			«ENDFOR»
		}
	'''
	
	@Traced def dispatch generateMember(Operation it) '''
		«_name»(«FOR it : parameters»«_name» : «_type[declaration.name]»«ENDFOR») : «_type[declaration.name]»
	'''
	
	@Traced def dispatch generateMember(Property it) '''
		«_name» : «_type[declaration.name]»
	'''
	
}
