/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.eclipse.generator

import com.google.inject.Inject
import io.typefox.traceexample.eclipse.myDsl.ClassDeclaration
import io.typefox.traceexample.eclipse.myDsl.Expression
import io.typefox.traceexample.eclipse.myDsl.FeatureCall
import io.typefox.traceexample.eclipse.myDsl.Model
import io.typefox.traceexample.eclipse.myDsl.MyDslFactory
import io.typefox.traceexample.eclipse.myDsl.Operation
import io.typefox.traceexample.eclipse.myDsl.Parameter
import io.typefox.traceexample.eclipse.myDsl.Property
import io.typefox.traceexample.eclipse.myDsl.TypeRef
import io.typefox.traceexample.eclipse.scoping.LibraryContainer
import java.util.Collection
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.generator.trace.node.CompositeGeneratorNode
import org.eclipse.xtext.generator.trace.node.Traced
import org.eclipse.xtext.generator.trace.node.TracedAccessors

import static extension com.google.common.io.Files.*

/**
 * A code generator that keeps track of traces between source and generated files.
 * 
 */
class MyDslGenerator extends AbstractGenerator {
	
	@TracedAccessors(MyDslFactory)
	static class MyDslTraceExtensions {}
	
	@Inject extension MyDslTraceExtensions
	
	@Inject LibraryContainer library
	
	protected def String getBaseName(Resource resource) {
		resource.URI.lastSegment.nameWithoutExtension
	}
	
	protected def Collection<Resource> findReferencedResources(Model model) {
		val resource = model.eResource
		val iterator = model.eAllContents.filter(TypeRef).map[declaration?.eResource].filter[ r |
			r !== null && r != resource && r.URI != library.URI
		]
		return iterator.toSet
	}

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val model = resource.contents.head as Model
		val baseName = resource.baseName
		
		if (model !== null) {
			fsa.generateTracedFile(baseName + '.h', model, '''
				/********************************
				 * Header file for «resource.URI.lastSegment»
				 */
				
				#ifndef «baseName.toUpperCase»
				#define «baseName.toUpperCase»
				
				«FOR r : model.findReferencedResources»
					#include "«r.baseName».h"
				«ENDFOR»
				
				«FOR c : model.types»
					
					«generateHeader(c)»
				«ENDFOR»
				
				#endif
			''')
			
			fsa.generateTracedFile(baseName + '.c', model, '''
				/********************************
				 * Implementation for «resource.URI.lastSegment»
				 */
				
				#include "«baseName».h"
				
				«FOR c : model.types.filter[!members.filter(Operation).empty]»
					
					«generateImpl(c)»
				«ENDFOR»
			''')
		}
	}
	
	@Traced protected def generateHeader(ClassDeclaration it) '''
		/*
		 * Declaration of «name» class
		 */
		typedef struct
		{
			«FOR p : members.filter(Property)»
				/* Property «name».«p.name» */
				«generateDeclaration(p)»
			«ENDFOR»
		} «_name»;
		«FOR o : members.filter(Operation)»
			
			/* Operation «name».«o.name» */
			«generateDeclaration(o)»;
		«ENDFOR»
	'''
	
	@Traced protected def generateImpl(ClassDeclaration it) '''
		/*
		 * Implementation of «name» operations
		 */
		
		«FOR o : members.filter(Operation)»
			
			/* Operation «name».«o.name» */
			«generateImpl(o)»
		«ENDFOR»
	'''
	
	private def generateType(TypeRef typeRef, boolean reference) {
		switch decl: typeRef.declaration {
			case library.getType('number'): 'double'
			case library.getType('string'): 'char*'
			case decl !== null && !decl.eIsProxy:
				if (reference)
					decl.name + '*'
				else
					decl.name
		}
	}
	
	private def isStructType(TypeRef typeRef) {
		switch typeRef.declaration {
			case library.getType('number'),
			case library.getType('string'): false
			default: true
		}
	}
	
	protected def generateDeclaration(Property prop) {
		val n = prop.trace
		n.append(prop._type[generateType(false)])
		n.append(' ')
		n.append(prop._name)
		n.append(';')
		return n
	}
	
	protected def generateDeclaration(Operation op) {
		val n = op.trace
		n.append(op._type[generateType(true)])
		n.append(' ')
		val classDecl = op.eContainer as ClassDeclaration
		n.append(classDecl.name)
		n.append('__')
		n.append(op._name)
		n.append('(')
		n.append(classDecl.name)
		n.append('* this')
		for (param : op.parameters) {
			n.append(', ')
			n.append(param.trace.append(param._type[generateType(true)]).append(' ').append(param._name))
		}
		n.append(')')
		return n
	}
	
	protected def generateImpl(Operation op) {
		val n = generateDeclaration(op)
		n.appendNewLine
		n.append('{')
		n.appendNewLine
		val body = n.indent
		val varName = op.expression.generateExpression(body, new Scope)
		body.append('return ')
		body.append(varName)
		body.append(';')
		n.appendNewLine
		n.append('}')
	}
	
	private def String generateExpression(Expression expression, CompositeGeneratorNode parent, Scope scope) {
		if (expression instanceof FeatureCall) {
			val n = trace(expression)
			val receiverVar = if (expression.receiver !== null)
				expression.receiver.generateExpression(n, scope)
			val paramVars = newArrayList
			expression.parameters.forEach[paramVars += generateExpression(n, scope)]
			val resultVar = scope.nextVarName
			n.append(generateType(expression.feature?.type, true))
			n.append(' ')
			n.append(resultVar)
			switch feature : expression.feature {
				Parameter: {
					n.append(' = ')
					n.append(feature.name)
				}
				Property: {
					n.append(' = ')
					if (isStructType(expression.feature?.type))
						n.append('&')
					n.append(receiverVar ?: 'this')
					n.append('->')
					n.append(feature.name)
				}
				Operation: {
					n.append(' = ')
					val classDecl = feature.eContainer as ClassDeclaration
					n.append(classDecl.name)
					n.append('__')
					n.append(feature._name)
					n.append('(')
					n.append(receiverVar ?: 'this')
					for (p : paramVars) {
						n.append(', ')
						n.append(p)
					}
					n.append(')')
				}
			}
			n.append(';')
			parent.append(n)
			parent.appendNewLine
			return resultVar
		}
	}
	
	private static class Scope {
		int nextVarIndex = 0
		
		def String nextVarName() {
			'''__local_«nextVarIndex++»'''
		}
	}
	
}
