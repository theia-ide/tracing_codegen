/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.javascript.web

import javax.servlet.annotation.WebServlet
import org.eclipse.xtext.util.DisposableRegistry
import org.eclipse.xtext.web.servlet.XtextServlet

/**
 * Deploy this class into a servlet container to enable DSL-specific services.
 */
@WebServlet(name = 'XtextServices', urlPatterns = '/xtext-service/*')
class CalcServlet extends XtextServlet {
	
	DisposableRegistry disposableRegistry
	
	override init() {
		super.init()
		val injector = new CalcWebSetup().createInjectorAndDoEMFRegistration()
		disposableRegistry = injector.getInstance(DisposableRegistry)
	}
	
	override destroy() {
		if (disposableRegistry !== null) {
			disposableRegistry.dispose()
			disposableRegistry = null
		}
		super.destroy()
	}
	
}
