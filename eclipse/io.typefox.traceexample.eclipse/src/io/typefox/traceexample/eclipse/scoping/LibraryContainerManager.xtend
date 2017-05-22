/*******************************************************************************
 * Copyright (c) 2017 TypeFox (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.traceexample.eclipse.scoping

import com.google.inject.Inject
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.resource.containers.StateBasedContainerManager

class LibraryContainerManager extends StateBasedContainerManager {
	
	@Inject LibraryContainer libraryContainer
	
	override getVisibleContainers(IResourceDescription desc, IResourceDescriptions resourceDescriptions) {
		val result = newArrayList
		result += super.getVisibleContainers(desc, resourceDescriptions)
		result += libraryContainer
		return result
	}
	
}