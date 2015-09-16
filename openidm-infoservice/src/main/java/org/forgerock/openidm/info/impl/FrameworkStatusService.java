/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2015 ForgeRock AS.
 */
package org.forgerock.openidm.info.impl;

/**
 * An OSGi Framework Status Service for storing the framework status indicated
 * by the last {@link org.osgi.framework.FrameworkEvent} event published.
 */
public class FrameworkStatusService {

	/**
     * A framework status service instance
     */
    private static FrameworkStatusService instance;
    
    /**
     * An integer representing the framework status.
     * See {@link org.osgi.framework.FrameworkEvent} for 
     */
    private int frameworkStatus;

    /**
     * Gets an instance of the framework status service.
     *
     * @return a cryptography service newBuilder
     */
    public static synchronized FrameworkStatusService getInstance() {
        if (instance == null) {
        	// Instantiate the instance and initialize the status to -1 
        	// indicating that the status has not yet been set.
            instance = new FrameworkStatusService();
            instance.setFrameworkStatus(-1);
        }
        return instance;
    }
    
    /**
     * Returns the current framework status.
     * 
     * @return an integer representing the framework status.
     */
    public int getFrameworkStatus() {
    	return this.frameworkStatus;
    }
    
    /**
     * Sets the current framework status.
     * 
     * @param frameworkStatus an integer representing the framework status.
     */
    public void setFrameworkStatus(int frameworkStatus) {
    	this.frameworkStatus = frameworkStatus; 
    }
}