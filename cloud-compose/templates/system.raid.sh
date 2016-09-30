# system.raid.sh
{%- if aws.raid is defined %}
yum -y install mdadm

{%- for raid in aws.raid %}

mdadm --create --verbose {{ raid.block }} --level={{ raid.level }} --name={{ raid.name }} --raid-devices={{ raid.devices|length }} {{ raid.devices|join(' ') }}
{%- if raid.journal is defined and not raid.journal %}
mkfs -t {{ raid.file_system }} -O ^has_journal {{ raid.block }}
{%- else %}
mkfs -t {{ raid.file_system }} {{ raid.block }}
{%- endif %}
echo -e '{{ raid.block }}\t{{ raid.mount }}\t{{ raid.file_system }}\t{{ raid.options|default("defaults,noatime", true) }}\t0\t0' >> /etc/fstab
mkdir -p {{ raid.mount }} 
mount {{ raid.mount }}
mdadm --verbose --detail --scan >> /etc/mdadm.conf

{%- endfor %}
{%- endif %}
