/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/

package io.typefox.traceexample.generator

import com.google.inject.Inject
import io.typefox.traceexample.myDsl.Model
import io.typefox.traceexample.tests.MyDslInjectorProvider
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith
import org.eclipse.xtext.generator.trace.ITraceRegionProvider
import org.eclipse.xtext.generator.trace.AbstractTraceRegion

@RunWith(XtextRunner)
@InjectWith(MyDslInjectorProvider)
class GeneratorTest {
	
	@Inject ParseHelper<Model> parseHelper
	@Inject IGenerator2 generator
	
	@Test def void testTracing() {
		val model = parseHelper.parse('''
			class Foo {
				name: Bar
			}
			class Bar {
				doStuff(x:Foo) : Foo
			}
		''')
		
		generator.doGenerate(model.eResource, fsa, [[false]]);
		Assert.assertEquals('''
			// generated
			class Foo {
				name : Bar
			}
			class Bar {
				doStuff(x : Foo) : Foo
			}
		'''.toString, lastContents.toString)
		
		val rootTraceRegion = (lastContents as ITraceRegionProvider).traceRegion
		// find the first region starting in line 2 // should be 'name'
		Assert.assertEquals("name", getText(rootTraceRegion.leafIterator.findFirst[myLineNumber === 2]))
		
		Assert.assertEquals("doStuff", getText(rootTraceRegion.leafIterator.findFirst[myLineNumber === 5]))
		
		// we have 8 regions in line 8
		Assert.assertEquals(8, rootTraceRegion.leafIterator.filter[myLineNumber === 5].size)
	}
	
	def getText(AbstractTraceRegion region) {
		lastContents.toString.substring(region.myOffset, region.myOffset + region.myLength)
	}
	
	CharSequence lastContents
	InMemoryFileSystemAccess fsa = new InMemoryFileSystemAccess() {
		override generateFile(String fileName, CharSequence contents) {
			lastContents = contents
			super.generateFile(fileName, contents)
		}
	}
	
}