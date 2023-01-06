# Lightdash

## Choose your warehouse

![](fig/lightdash_1_warehouse.png)

## Select the option: Create project manually

![](fig/lightdash_2_connect_project.png)

## Select the option: I've Defined them!

![](fig/lightdash_3_project_ready.png)

## Add your warehouse connection

You need to specify your Google Project, the location and the lightdash service account key file that Terraform created.

Either it's already in your credentials folder, otherwise you can just generate it with the following command

```bash
make lightdash-credentials
```

Finally you just upload your json keyfile here.

![](fig/lightdash_4_bq_connection.png)

## Connect to your dbt project

I have chosen to connect through our Github project, so you will need a Personal Access Token that you can create specifically for this Lightdash isntance.

You're going to need the dbt project path under your github repository, the dbt profile target and the bigquery dataset of the target.

![](fig/lightdash_5_dbt_connection.png)

And that's it, you're good to go.
