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
 * Copyright 2015-2016 ForgeRock AS.
 */
package org.forgerock.openidm.maintenance.upgrade;

import org.forgerock.commons.launcher.OSGiFrameworkService;
import org.forgerock.openidm.util.FileUtil;
import org.osgi.framework.Bundle;
import org.osgi.framework.wiring.FrameworkWiring;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Factory;
import org.testng.annotations.Test;

import java.io.File;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;


public class BundleHandlerTest {

    private String[] arguments;

    private OSGiFrameworkService service;

    private BundleHandler bundleHandler;

    // Path to the helloworld bundle jar
    private Path bundlePath;

    private static final String ARCHIVE_EXTENSION = ".test.bak";

    private Map<String, Bundle> installedBundles = new HashMap<String, Bundle>();

    private void setInstalledBundles() {
        for (Bundle bundle : service.getSystemBundle().getBundleContext().getBundles()) {
            installedBundles.put(bundle.getLocation(), bundle);
        }
    }

    private void updateInstalledBundles() {
        for (Bundle bundle : service.getSystemBundle().getBundleContext().getBundles()) {
            installedBundles.put(bundle.getLocation(), bundle);
        }
    }

    @Factory(dataProvider = "provider")
    public BundleHandlerTest( String[] args) {
        this.arguments = args;
    }

    @DataProvider
    public static Object[][] provider() throws Exception {
        String bundleHandlerDir = URLDecoder.decode(new File(BundleHandlerTest.class.getResource("/bundleHandler/")
                                                .toURI()).toString(), "utf-8");

        String install = URLDecoder.decode(new File(BundleHandlerTest.class.getResource("/")
                                        .toURI().resolve("../osgi/")).toString(), "utf-8");
        return new Object[][] {
            new Object[] {
                new String[] {
                    "-i", install, "-p", bundleHandlerDir, "-w", bundleHandlerDir, "-c", "bin/launcher.json",
                    "-s", "felix-cache"
                }
            }
        };
    }

    @BeforeClass
    public void beforeClass() throws Exception {
        service = new OSGiFrameworkService();
        service.init(arguments);
        service.setNewThread(true);
        service.start();
        System.out.println("Framework Started - OK");
        assertThat(service.getSystemBundle()).isNotNull();
        setInstalledBundles();
        bundleHandler = new BundleHandler(service.getSystemBundle().getBundleContext(), ARCHIVE_EXTENSION,
                new LogHandler() {
                    @Override
                    public void log(Path filePath, Path backupPath) {
                    }
                });
        bundlePath = Paths.get(service.getProjectURI().resolve("bundle/HelloWorld-1.0-SNAPSHOT.jar"));
    }

    @AfterClass
    public void afterClass() throws Exception {
        service.stop();
    }

    private void stopBundle(Bundle bundle) throws Exception{
        bundleHandler.stopBundle(bundle);
        // wait up to 5 seconds for the framework to finish
        int waited = 0;
        while (bundle.getState() != Bundle.RESOLVED && waited < 5000) {
            Thread.sleep(100);
            waited += 100;
        }
    }

    private void uninstallBundle(Bundle bundle) throws Exception {
        bundleHandler.uninstallBundle(bundle);
        updateInstalledBundles();
    }

    private Bundle installBundle(Path path) throws Exception {
        bundleHandler.installBundle(path);
        updateInstalledBundles();
        return installedBundles.get(path.toUri().toString());
    }

    private void startBundle(Bundle bundle) throws Exception {
        bundleHandler.startBundle(bundle);
        // Wait for bundle to start for up to 5 seconds
        int waited = 0;
        while (bundle.getState() != Bundle.ACTIVE && waited < 5000) {
            Thread.sleep(100);
            waited += 100;
        }
    }

    @Test
    public void testStopBundle() throws Exception {
        // install the bundle
        Bundle bundle = installBundle(bundlePath);

        // start the bundle
        startBundle(bundle);

        // Assert that the bundle is installed and running
        assertThat(bundle.getState()).isEqualTo(Bundle.ACTIVE);

        // stop the bundle
        stopBundle(bundle);

        // assert that bundle is in stopped state
        assertThat(bundle.getState()).isEqualTo(Bundle.RESOLVED);
    }

    @Test
    public void testUninstallBundle() throws Exception {

        // install bundle
        Bundle bundle = installBundle(bundlePath);
        // start bundle
        startBundle(bundle);

        // assert that the bundle is installed in the framework
        assertThat(bundle).isNotNull();

        // stop bundle
        stopBundle(bundle);

        // after uninstalling we want to refresh the packages to use this new bundle
        Set<Bundle> bundlesToRefresh = new HashSet<Bundle>();
        bundlesToRefresh.add(bundle);

        // uninstall bundle
        uninstallBundle(bundle);

        // refresh to show uninstalled bundle
        FrameworkWiring frameworkWiring = service.getSystemBundle().adapt(FrameworkWiring.class);
        frameworkWiring.refreshBundles(bundlesToRefresh);

        // assert that the bundle is in uninstalled state
        bundle = installedBundles.get(bundlePath.toUri().toString());
        assertThat(bundle.getState()).isEqualTo(Bundle.UNINSTALLED);

        // at the "system" level remove the bundle from the bundles/directory now
    }

    @Test
    public void testInstallBundle() throws Exception {
        // create bundle info for installing
        Bundle bundle = installedBundles.get(bundlePath);

        // check that the bundle does not exist already in the framework
        assertThat(bundle).isNull();

        // install the bundle
        bundle = installBundle(bundlePath);

        // validate that the bundle has actually been installed
        assertThat(bundle).isNotNull();
        assertThat(bundle.getState()).isEqualTo(Bundle.INSTALLED);

    }

    @Test
    public void testStartBundle() throws Exception {
        // install bundle
        Bundle bundle = installBundle(bundlePath);

        // start the bundle
        startBundle(bundle);

        // assert that the bundle is now started in the Active state
        assertThat(bundle.getState()).isEqualTo(Bundle.ACTIVE);

    }

    /**
     * This test updates a bundle that has the same version as
     * the previous but contains a different class implementation.
     */
    @Test
    public void testUpdateBundle() throws Exception {
        Path backupFile = null;
        try {
            // Start API
            testStartBundle();

            // install bundle
            Path bundlePathV1 =
                    Paths.get(service.getProjectURI().resolve("bundle/HelloImplementation-1.0-SNAPSHOT.jar"));
            Bundle bundle = installBundle(bundlePathV1);

            // start the bundle
            startBundle(bundle);

            // assert that the bundle is now started in the Active state
            assertThat(bundle.getState()).isEqualTo(Bundle.ACTIVE);

            String bundle1Version = FileUtil.readManifest(bundlePathV1.toFile()).getValue("Bundle-Version");
            assertThat(bundle1Version).isEqualTo(bundle.getVersion().toString());

            Path bundlePathV2  =
                    Paths.get(service.getProjectURI().resolve("bundle/updated/HelloImplementation-1.0-SNAPSHOT.jar"));

            bundleHandler.upgradeBundle(bundlePathV2, "HelloImplementation");

            // assert that the old file has been backed up with archive extension
            backupFile = Paths.get(new URI(bundlePathV1.toUri().toString().concat(ARCHIVE_EXTENSION)));
            assertThat(backupFile).isNotNull();

            // update bundle
            bundleHandler.updateBundle(bundle);

            // refresh all bundles that would need the new import from bundle2
            FrameworkWiring frameworkWiring = service.getSystemBundle().adapt(FrameworkWiring.class);
            frameworkWiring.refreshBundles(null);
        } finally {
            // cleanup this test
            if (backupFile != null) {
                Files.delete(backupFile);
            }
        }
    }
}