/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.generator

import com.google.inject.Inject
import io.typefox.traceexample.javascript.calc.BinaryExpression
import io.typefox.traceexample.javascript.calc.Calculation
import io.typefox.traceexample.javascript.calc.Definition
import io.typefox.traceexample.javascript.calc.FeatureCall
import io.typefox.traceexample.javascript.calc.NumberLiteral
import io.typefox.traceexample.javascript.calc.Output
import io.typefox.traceexample.javascript.calc.UnaryExpression
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.generator.trace.node.CompositeGeneratorNode
import org.eclipse.xtext.generator.trace.node.GeneratorNodeProcessor
import org.eclipse.xtext.generator.trace.node.TracingSugar
import org.eclipse.xtext.resource.XtextResource

/**
 * Generates code from your model files on save.
 */
class CalcGenerator extends AbstractGenerator {
	
	@Inject extension TracingSugar
	
	@Inject GeneratorNodeProcessor processor
	
	@Inject SourceMapGenerator sourceMapGenerator

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val calculation = resource.contents.head as Calculation
		if (calculation !== null) {
			
			val rootNode = trace(calculation, '''
				// Generated from «resource.URI.lastSegment»
				define({
					execute: function() {
						«FOR statement : calculation.statements»
							«generate(statement)»
						«ENDFOR»
					}
				});
				
				//# sourceMappingURL=/xtext-service/generate?resource=«resource.URI»&artifact=calc.js.map
			''')
			
			val result = processor.process(rootNode)
			fsa.generateFile('calc.js', result)
			val sourceMap = sourceMapGenerator.generateSourceMap(result, resource as XtextResource)
			fsa.generateFile('calc.js.map', sourceMap)
		} else {
			fsa.generateFile('calc.js', 'define({});')
		}
	}
	
	def dispatch CompositeGeneratorNode generate(Definition definition) {
		val node = trace(definition)
		node.append('var ')
		node.append(definition.name)
		node.append(' = ')
		node.append(generate(definition.expression))
		node.append(';')
		return node
	}
	
	def dispatch CompositeGeneratorNode generate(Output output) {
		val node = trace(output)
		node.append('window.alert(')
		node.append(generate(output.expression))
		node.append(');')
		return node
	}
	
	def dispatch CompositeGeneratorNode generate(BinaryExpression binaryExpression) {
		val node = trace(binaryExpression)
		node.append('(')
		node.append(generate(binaryExpression.left))
		node.append(' ')
		node.append(binaryExpression.operator)
		node.append(' ')
		node.append(generate(binaryExpression.right))
		node.append(')')
		return node
	}
	
	def dispatch CompositeGeneratorNode generate(UnaryExpression unaryExpression) {
		val node = trace(unaryExpression)
		node.append('(')
		node.append(unaryExpression.operator)
		node.append(generate(unaryExpression.expression))
		node.append(')')
		return node
	}
	
	def dispatch CompositeGeneratorNode generate(FeatureCall featureCall) {
		val node = trace(featureCall)
		node.append(featureCall.feature?.name ?: '/* unresolved definition */')
		return node
	}
	
	def dispatch CompositeGeneratorNode generate(NumberLiteral numberLiteral) {
		val node = trace(numberLiteral)
		node.append(numberLiteral.value)
		return node
	}
	
}
