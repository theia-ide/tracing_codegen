/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.eclipse.scoping

import io.typefox.traceexample.eclipse.myDsl.ClassDeclaration
import io.typefox.traceexample.eclipse.myDsl.FeatureCall
import io.typefox.traceexample.eclipse.myDsl.Operation
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

import static io.typefox.traceexample.eclipse.myDsl.MyDslPackage.Literals.*

import static extension org.eclipse.xtext.EcoreUtil2.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class MyDslScopeProvider extends AbstractMyDslScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		switch reference {
			case FEATURE_CALL__FEATURE:
				getFeatureScope(context)
			default:
				super.getScope(context, reference)
		}
	}
	
	protected def getFeatureScope(EObject context) {
		val ClassDeclaration classDecl =
			if (context instanceof FeatureCall && (context as FeatureCall).receiver !== null)
				(context as FeatureCall).receiver.feature?.type?.declaration
			else
				context.getContainerOfType(ClassDeclaration)
		var scope = if (classDecl !== null) Scopes.scopeFor(classDecl.members) else IScope.NULLSCOPE
		val operation = context.getContainerOfType(Operation)
		if (operation !== null) {
			scope = Scopes.scopeFor(operation.parameters, scope)
		}
		return scope
	}
	
}
