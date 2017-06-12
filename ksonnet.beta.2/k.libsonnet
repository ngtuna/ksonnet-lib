local k8s = import "k8s.libsonnet";

local extensions = k8s.extensions;
local core = k8s.core;

local deployment = extensions.v1beta1.deployment;
local container = deployment.mixin.spec.template.spec.containersType;
local volume = deployment.mixin.spec.template.spec.volumesType;

k8s + {
  core:: core + {
    v1:: core.v1 + {
      list:: {
        new(items)::
          {apiVersion: "v1"} +
          {kind: "List"} +
          {items: items},
      },

      service:: core.v1.service + {
        new(name, selectorLabels, ports)::
          super.new() +
          super.mixin.metadata.name(name) +
          super.mixin.spec.selector(selectorLabels) +
          super.mixin.spec.ports(ports),

        mixin:: core.v1.service.mixin + {
          spec:: core.v1.service.mixin.spec + {
            portsType:: core.v1.service.mixin.spec.portsType + {
              tcp(servicePort, targetPort)::
                super.new() +
                super.port(servicePort) + {
                  targetPort: targetPort,
                },
            },
          },
        },
      },
    },
  },

  extensions:: extensions + {
    v1beta1:: extensions.v1beta1 + {
      deployment:: extensions.v1beta1.deployment + {
        new(name, replicas, containers, podLabels={})::
          super.new() +
          super.mixin.metadata.name(name) +
          super.mixin.spec.replicas(replicas) +
          super.mixin.spec.template.spec.containers(containers) +
          super.mixin.spec.template.metadata.labels(podLabels),

        mapContainers(f):: {
          local podContainers = super.spec.template.spec.containers,
          spec+: {
            template+: {
              spec+: {
                // IMPORTANT: This overwrites the `containers` field
                // for this deployment.
                containers: std.map(f, podContainers),
              },
            },
          },
        },

        mixin:: deployment.mixin + {
          // extensions.v1beta1.deployment.mixin.spec.template.spec.containersType
          spec:: deployment.mixin.spec + {
            template:: deployment.mixin.spec.template + {
              spec:: deployment.mixin.spec.template.spec + {
                containersType:: container + {
                  new(name, image)::
                    super.name(name) +
                    super.image(image),

                  volumeMountsType:: container.volumeMountsType + {
                    new(name, mountPath)::
                      super.new() +
                      super.name(name) +
                      super.mountPath(mountPath),
                  },

                  portsType:: container.portsType + {
                    named(name, containerPort)::
                      super.new() +
                      super.name(name) +
                      super.containerPort(containerPort),
                  }
                },

                volumesType:: volume + {
                  fromPvc(name, claimName)::
                    super.new() +
                    super.name(name) + {
                      persistentVolumeClaim: claimName
                    },
                }
              },
            },
          },
        },
      },
    },
  },
}
