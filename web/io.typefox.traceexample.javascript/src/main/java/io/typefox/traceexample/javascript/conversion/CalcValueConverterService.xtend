/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.conversion

import com.google.inject.Inject
import org.eclipse.xtext.common.services.DefaultTerminalConverters
import org.eclipse.xtext.conversion.IValueConverter
import org.eclipse.xtext.conversion.ValueConverter

class CalcValueConverterService extends DefaultTerminalConverters {
	
	@Inject NumberValueConverter numberValueConverter
	
	@ValueConverter(rule = "Number")
	def IValueConverter<Double> number() {
		return numberValueConverter
	}
	
}