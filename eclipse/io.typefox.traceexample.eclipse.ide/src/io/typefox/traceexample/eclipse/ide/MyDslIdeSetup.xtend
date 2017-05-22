/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.eclipse.ide

import com.google.inject.Guice
import io.typefox.traceexample.eclipse.MyDslRuntimeModule
import io.typefox.traceexample.eclipse.MyDslStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class MyDslIdeSetup extends MyDslStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new MyDslRuntimeModule, new MyDslIdeModule))
	}
	
}
