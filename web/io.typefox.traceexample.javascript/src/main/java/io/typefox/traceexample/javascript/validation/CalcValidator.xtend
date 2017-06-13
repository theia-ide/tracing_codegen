/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.validation

import io.typefox.traceexample.javascript.calc.Calculation
import io.typefox.traceexample.javascript.calc.Definition
import io.typefox.traceexample.javascript.calc.FeatureCall
import org.eclipse.xtext.validation.Check

import static io.typefox.traceexample.javascript.calc.CalcPackage.Literals.*
import static extension org.eclipse.xtext.EcoreUtil2.*

/**
 * This class contains custom validation rules. 
 */
class CalcValidator extends AbstractCalcValidator {
	
	@Check
	def checkDuplicateDefinitions(Calculation calculation) {
		val names = newHashMap
		for (definition : calculation.statements.filter(Definition)) {
			if (names.containsKey(definition.name)) {
				val otherDef = names.get(definition.name)
				if (otherDef !== null) {
					error('Duplicate definition name.', otherDef, DEFINITION__NAME)
					names.put(definition.name, null)
				}
				error('Duplicate definition name.', definition, DEFINITION__NAME)
			} else {
				names.put(definition.name, definition)
			}
		}
	}
	
	@Check
	def checkVariableReferencesItself(FeatureCall call) {
		val container = call.getContainerOfType(Definition)
		if (container !== null && container == call.feature) {
			error('A definition must not reference itself.', FEATURE_CALL__FEATURE);
		}
	}
	
}
