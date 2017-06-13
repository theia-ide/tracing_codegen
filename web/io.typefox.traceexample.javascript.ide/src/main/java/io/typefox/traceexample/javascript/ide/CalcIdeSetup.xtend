/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.ide

import com.google.inject.Guice
import io.typefox.traceexample.javascript.CalcRuntimeModule
import io.typefox.traceexample.javascript.CalcStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class CalcIdeSetup extends CalcStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new CalcRuntimeModule, new CalcIdeModule))
	}
	
}
