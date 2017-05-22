/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.eclipse.validation

import io.typefox.traceexample.eclipse.myDsl.ClassDeclaration
import io.typefox.traceexample.eclipse.myDsl.Expression
import io.typefox.traceexample.eclipse.myDsl.FeatureCall
import io.typefox.traceexample.eclipse.myDsl.Model
import io.typefox.traceexample.eclipse.myDsl.Operation
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.validation.Check

import static io.typefox.traceexample.eclipse.myDsl.MyDslPackage.Literals.*

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class MyDslValidator extends AbstractMyDslValidator {
	
	@Check
	def void checkUniqueNames(Model model) {
		checkUniqueNames(model.types, CLASS_DECLARATION__NAME)
	}
	
	@Check
	def void checkUniqueNames(ClassDeclaration classDecl) {
		checkUniqueNames(classDecl.members, FEATURE__NAME)
	}
	
	@Check
	def void checkUniqueNames(Operation operation) {
		checkUniqueNames(operation.parameters, FEATURE__NAME)
	}
	
	protected def void checkUniqueNames(Iterable<? extends EObject> elements, EStructuralFeature nameFeature) {
		val usedNames = newHashMap
		for (e : elements) {
			val name = e.eGet(nameFeature) as String
			if (usedNames.containsKey(name)) {
				val other = usedNames.get(name)
				if (other !== null) {
					error("Name is already used", other, nameFeature)
					usedNames.put(name, null)
				}
				error("Name is already used", e, nameFeature)
			} else {
				usedNames.put(name, e)
			}
		}
	}
	
	protected def getType(Expression expression) {
		if (expression instanceof FeatureCall)
			expression.feature?.type?.declaration
	}
	
	@Check
	def void checkParameters(FeatureCall featureCall) {
		val feature = featureCall.feature
		if (feature !== null && !feature.eIsProxy) {
			if (feature instanceof Operation) {
				if (!featureCall.isParenthesized)
					error('''The operation must be called with parentheses: «feature.name»()''', null)
				else if (featureCall.parameters.size != feature.parameters.size)
					error('''The operation «feature.name» has «feature.parameters.size» parameters''', null)
				else {
					for (var i = 0; i < featureCall.parameters.size; i++) {
						val expectedType = feature.parameters.get(i).type.declaration
						val actualType = featureCall.parameters.get(i).type
						if (expectedType !== null && !expectedType.eIsProxy && expectedType != actualType) {
							if (actualType !== null && !actualType.eIsProxy)
								error('''Expected type «expectedType.name», but got «actualType.name»''', FEATURE_CALL__PARAMETERS, i)
							else
								error('''Expected type «expectedType.name»''', FEATURE_CALL__PARAMETERS, i)
						}
					}
				}
			} else if (featureCall.isParenthesized) {
				error('''The «feature.eClass.name.toLowerCase» must be called without parentheses''', null)
			}
		}
	}
	
	@Check
	def void checkReturnValue(Operation operation) {
		val expectedType = operation.type.declaration
		if (operation.expression === null) {
			if (expectedType !== null && !expectedType.eIsProxy)
				error('''The operation must return a value of type «expectedType.name»''', FEATURE__NAME)
			else
				error('''The operation must return a value''', FEATURE__NAME)
		} else {
			val actualType = operation.expression.type
			if (expectedType !== null && !expectedType.eIsProxy && expectedType != actualType) {
				if (actualType !== null && !actualType.eIsProxy)
					error('''Expected type «expectedType.name», but got «actualType.name»''', OPERATION__EXPRESSION)
				else
					error('''Expected type «expectedType.name»''', OPERATION__EXPRESSION)
			}
		}
	}
	
}
