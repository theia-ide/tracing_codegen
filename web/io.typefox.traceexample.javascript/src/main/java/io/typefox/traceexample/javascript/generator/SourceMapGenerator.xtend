/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.generator

import com.google.gson.Gson
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend2.lib.StringConcatenation
import org.eclipse.xtext.generator.trace.AbstractTraceRegion
import org.eclipse.xtext.generator.trace.node.GeneratorNodeProcessor
import org.eclipse.xtext.resource.XtextResource

class SourceMapGenerator {
	
	def CharSequence generateSourceMap(GeneratorNodeProcessor.Result result, XtextResource resource) {
		val sourceMap = new SourceMap => [
			version = 3
			sources = #['generated:///' + resource.URI.toString]
			sourcesContent = #[resource.parseResult.rootNode.text]
			names = emptyList
			val sourceDocument = new Document(sourcesContent.head)
			val targetDocument = new Document(result.toString)
			mappings = generateMappings(result.traceRegion, sourceDocument, targetDocument).toString
		]
		val gson = new Gson
		return gson.toJson(sourceMap)
	}
	
	protected def CharSequence generateMappings(AbstractTraceRegion rootTrace, Document source, Document target) {
		val segments = newArrayList
		val iterator = rootTrace.treeIterator
		var targetLine = 0
		while (iterator.hasNext) {
			val trace = iterator.next
			while (trace.myLineNumber > targetLine) {
				targetLine++
			}
			val sourceLine = trace.associatedLocations.head.lineNumber
			val sourceColumn = source.getColumn(trace.associatedLocations.head.offset)
			val targetColumn = target.getColumn(trace.myOffset)
			segments += new Segment(sourceLine, sourceColumn, targetLine, targetColumn)
		}
		return generateSegments(segments)
	}
	
	protected def CharSequence generateSegments(List<Segment> segments) {
		val result = new StringConcatenation
		
		var previousSourceLine = 0
		var previousSourceColumn = 0
		var previousTargetLine = 0
		var previousTargetColumn = 0
		for (segment : segments) {
			while (segment.targetLine != previousTargetLine) {
				result.append(';')
				previousTargetLine++
				previousTargetColumn = 0
			}
			if (previousTargetColumn > 0) {
				result.append(',')
			}
			// Generated column
			result.append(encodeVlQ(segment.targetColumn - previousTargetColumn))
			previousTargetColumn = segment.targetColumn
			// Original file this appeared in
			result.append(encodeVlQ(0))
			// Original line number
			result.append(encodeVlQ(segment.sourceLine - previousSourceLine))
			previousSourceLine = segment.sourceLine
			// Original column
			result.append(encodeVlQ(segment.sourceColumn - previousSourceColumn))
			previousSourceColumn = segment.sourceColumn
		}

		return result
	}
	
	static val VLQ_BASE_SHIFT = 5
	static val VLQ_BASE = 1 << VLQ_BASE_SHIFT
	static val VLQ_BASE_MASK = VLQ_BASE - 1
	static val VLQ_CONTINUATION_BIT = VLQ_BASE
	
	protected def CharSequence encodeVlQ(int value) {
		val encoded = new StringConcatenation
		var vlq = toVLQSigned(value)
		do {
			var digit = vlq.bitwiseAnd(VLQ_BASE_MASK)
			vlq = vlq >>> VLQ_BASE_SHIFT
			if (vlq > 0) {
				digit = digit.bitwiseOr(VLQ_CONTINUATION_BIT)
			}
			encoded.append(encodeBase64(digit))
		} while (vlq > 0)
		return encoded
	}
	
	private def toVLQSigned(int x) {
		if (x < 0)
			((-x) << 1) + 1
		else
			x << 1
	}
	
	static val BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	
	protected def String encodeBase64(int value) {
		if (value < 0 || value >= BASE64_CHARS.length)
			throw new IllegalArgumentException('Must be between 0 and ' + (BASE64_CHARS.length - 1) + ': ' + value)
		return Character.toString(BASE64_CHARS.charAt(value))
	}
	
	private static class Document {
		val List<Integer> lineLengths
		
		new(String text) {
			lineLengths = new ArrayList(text.split('\\n').map[length + 1])
		}
		
		def getColumn(int offset) {
			var lineOffset = 0
			for (lineLength : lineLengths) {
				val lineEnd = lineOffset + lineLength
				if (offset < lineEnd)
					return offset - lineOffset
				lineOffset = lineEnd
			}
			return offset - lineOffset
		}
	}
	
	@Data
	private static class Segment {
		val int sourceLine
		val int sourceColumn
		val int targetLine
		val int targetColumn
	}
	
}