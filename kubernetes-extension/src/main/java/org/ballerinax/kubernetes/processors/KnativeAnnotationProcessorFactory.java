/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinax.kubernetes.processors;

import org.ballerinax.kubernetes.exceptions.KubernetesPluginException;
import org.ballerinax.kubernetes.models.knative.KnativeContext;
import org.ballerinax.kubernetes.processors.knative.KnativeConfigMapAnnotationProcessor;
import org.ballerinax.kubernetes.processors.knative.KnativeSecretAnnotationProcesser;
import org.ballerinax.kubernetes.processors.knative.KnativeServiceAnnotationProcessor;

/**
 * Annotation processor factory for knative.
 */
public class KnativeAnnotationProcessorFactory {

    public static AnnotationProcessor getAnnotationProcessorInstance(String type) throws KubernetesPluginException {
        // set can process to true so that this value can be accessed from code generated method.
        KnativeContext.getInstance().getDataHolder().setCanProcess(true);
        KnativeAnnotation knativeAnnotation = KnativeAnnotation.valueOf(type);
        switch (knativeAnnotation) {
            case Service:
                return new KnativeServiceAnnotationProcessor();
            case Secret:
                return new KnativeSecretAnnotationProcesser();
            case ConfigMap:
                return new KnativeConfigMapAnnotationProcessor();
            default:
                KnativeContext.getInstance().getDataHolder().setCanProcess(false);
                throw new KubernetesPluginException("error while getting annotation processor for type: " + type);
        }
    }

    private enum KnativeAnnotation {
        Service,
        HPA,
        Secret,
        ConfigMap,
        ResourceQuota,
    }
}
