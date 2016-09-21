# system.raid.sh
{%- if aws.raid is defined %}
yum -y install mdadm

{%- for raid in aws.raid %}

mdadm --create --verbose {{ raid.block }} --level={{ raid.level }} --name={{ raid.name }} --raid-devices={{ raid.devices|length }} {{ raid.devices|join(' ') }}
mkfs -t {{ raid.file_system }} {{ raid.block }}
echo -e '{{ raid.block }}\t{{ raid.mount }}\t{{ raid.file_system }}\t{{ raid.options|default("defaults", true) }}\t0\t0' >> /etc/fstab
mkdir -p {{ raid.mount }} 
mount {{ raid.mount }}

{%- endfor %}
{%- endif %}
