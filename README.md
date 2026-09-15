# amplicon_16S_rRNA_full-length_pacbio_qiime_nf

[English](#english) | [한국어](#korean)

<a id="english"></a>

## English

A Nextflow DSL2 workflow for PacBio full-length 16S CCS reads with QIIME 2, Docker, Singularity or Apptainer.

### New to Nextflow? Start here

Nextflow connects analysis steps and manages their execution. In this project, it passes your reads through quality control and QIIME 2 in the required order. A container packages the software needed by a step; Docker, Singularity and Apptainer are programs that run those containers. You do not need to write Nextflow code to use this pipeline.

Read these official resources in order:

1. [Nextflow overview and documentation](https://docs.seqera.io/nextflow): understand what Nextflow does.
2. [Official installation guide](https://docs.seqera.io/nextflow/install): install Java and Nextflow and set up your command path.
3. [Official training portal](https://training.nextflow.io/): choose the **Nextflow Run** course to learn how to run existing pipelines.
4. [Hello Nextflow](https://training.nextflow.io/latest/hello_nextflow/): optional hands-on lessons for learning to write pipelines.

For this repository, use Linux x86-64, Nextflow >=26.04.2, a compatible Java version (Java 17 is used in CI), host Python 3, Git, and one container runtime. On a shared server, ask your administrator which runtime is available. Initial container downloads require network access and disk space. Samplesheet validation uses host Python to check input paths; the analysis tools run in containers.

Open a terminal and check your installation. The examples below assume Docker; substitute the runtime installed on your server.

```bash
java -version
nextflow -version
python3 --version
git --version
docker --version
```

### Download and run your first test

Clone the repository and enter its directory. All subsequent commands assume you are in this directory. The `.` in `nextflow run .` means “run the pipeline in the current directory.”

Start with the bundled synthetic QC test. You do not need your own reads or a taxonomy classifier. The first run may take longer while containers download. A successful check prints `PASS: QC outputs and poly-G removal`.

```bash
git clone https://github.com/KitHubb/amplicon_16S_rRNA_full-length_pacbio_qiime_nf.git
cd amplicon_16S_rRNA_full-length_pacbio_qiime_nf
nextflow run . -profile test,docker
python3 tests/check_outputs.py results/test
```

### Command options at a glance

| Option | Meaning |
|---|---|
| `-profile docker` | Run with Docker; use `singularity` or `apptainer` for those runtimes. |
| `-profile test,docker` | Combine the small test settings with Docker. Select only one runtime. |
| `--input` | Path to your samplesheet CSV. |
| `--outdir` | Directory for published results. |
| `--taxonomy_classifier` | Compatible QIIME 2 classifier `.qza` file. |
| `--taxonomy_enabled false` | Skip taxonomy when no classifier is available. |
| `--phylogeny_enabled false` | Skip phylogenetic tree construction. |
| `--stop_after_qc true` | Stop after QC, before QIIME 2 import. |
| `-resume` | Reuse eligible cached tasks from an earlier run. Keep `work/` and `.nextflow/`. |
| `-c local.config` | Add your local settings, e.g. `nextflow -c local.config run . ...`. |

A single hyphen marks a Nextflow option; two hyphens mark a pipeline parameter. Replace `/absolute/path/to/...` examples with real paths. A trailing `\` continues a command on the next line.

### Workflow and tested environment

The workflow processes PacBio full-length 16S CCS/HiFi reads. DADA2 uses the configured primer pair, a 1000–1600 bp length range and 16 threads by default. Other DADA2 options use the installed QIIME 2 defaults.

Tested versions: Nextflow 26.04.2, Singularity-CE 3.9.2, FastQC 0.12.1, MultiQC 1.27.1, Cutadapt 5.2 and QIIME 2 Amplicon 2025.7.

```text
TAR / HiFi FASTQ
  -> Samplesheet validation -> PacBio input preparation
  -> Raw FastQC / MultiQC
  -> Cutadapt quality trimming + poly-G/poly-A cleanup
  -> Clean FastQC / MultiQC + cleanup summary
  -> QIIME 2 single-end manifest / import
  -> DADA2 denoise-ccs -> Table / sequences / statistics summaries
  -> Taxonomy: SILVA classify-sklearn (optional)
  -> Phylogeny: MAFFT + FastTree (optional)
```

### Automatic containers and local images

Nextflow automatically downloads these version-pinned public images. QC tools use [BioContainers](https://bioconda.github.io/recipes/multiqc/README.html); QIIME 2 uses its [official distribution](https://github.com/qiime2/distributions) with the DADA2, classifier and phylogeny plugins.

| Parameter | Default image |
|---|---|
| `fastqc_container` | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0` |
| `multiqc_container` | `quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0` |
| `cutadapt_container` | `quay.io/biocontainers/cutadapt:5.2--py310h1fe012e_0` |
| `qiime_container` | `quay.io/qiime2/amplicon:2025.7` |

Replace `docker` with `singularity` or `apptainer` to use automatic conversion and caching. Docker runs with your host UID/GID so outputs belong to your account. Custom `_container` parameters can point to compatible images or digest-pinned references.

To reuse local SIF files, select Singularity/Apptainer and set `--qc_sif`, `--cutadapt_sif` and `--qiime_sif`. They default to null and are ignored by Docker. The combined QC image must include FastQC and MultiQC; the Cutadapt image must also include Bash, gzip and tar. Store machine-specific settings in an untracked `local.config`.

The classifier is not bundled. The default parameter YAML does not set its path.

### Prepare your samplesheet

A samplesheet is a CSV that tells the pipeline which file belongs to each sample. Use the exact header below. Sample IDs must be unique and use letters, numbers, dots, underscores or hyphens, starting with a letter or number. `assay_id` must be `16S_full`.

Supported inputs: `fastq` (`.fastq`, `.fastq.gz`, `.fq`, `.fq.gz`) or `tar` (a sample-level `.tar` containing FASTQ files). Relative paths resolve against the original samplesheet directory; absolute paths are also accepted.

For TAR input, each sample is extracted separately, files containing `_trim_` are excluded, and retained reads are normalized to `<sample_id>.raw.fastq.gz`. Original inputs are not modified.

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
Sample01,Run01,16S_full,1,Stool,tar,/data/FASTQ/Run01/Sample01_cell1.tar
Sample02,Run01,16S_full,1,Stool,fastq,/data/FASTQ/Run01/Sample02_HiFi.fastq.gz
```

### Generate a samplesheet from a directory

The helper accepts an input directory, output CSV, run ID, input type, library round and sample type, in that order. Replace these examples with your data. Review the generated sample IDs and metadata before analysis.

```bash
bash bin/make_samplesheet.sh   /data/FASTQ/Run01   assets/my_samplesheet.csv   Run01 tar 1 Stool
```

### Run your own data

First run without taxonomy if you do not yet have a compatible classifier. This example keeps phylogeny enabled. Run the synthetic test first on a small machine: production DADA2 requests 16 CPUs and 32 GB memory by default, with other tasks also using resources.

```bash
nextflow run . -profile docker   --input assets/my_samplesheet.csv   --outdir results/analysis   --taxonomy_enabled false   -resume
```

### Enable taxonomy

Provide a classifier compatible with QIIME 2 Amplicon 2025.7. The previously tested setup used `silva-138-99-nb-classifier.qza` (SILVA 138 99% Naive Bayes). The filename alone does not guarantee compatibility. Taxonomy and phylogeny are enabled by default; each can be disabled independently.

```bash
nextflow run . -profile docker   --input assets/my_samplesheet.csv   --taxonomy_classifier /absolute/path/to/compatible-classifier.qza   --outdir results/analysis   -resume
```

### Try one real sample first

Use a samplesheet you already prepared. This command writes the one-sample CSV into the same directory so relative input paths remain valid. Run core analysis first, then use the taxonomy example above with this one-sample input to enable downstream steps.

```bash
{
  head -n 1 assets/my_samplesheet.csv
  sed -n '2p' assets/my_samplesheet.csv
} > assets/one_sample.csv

nextflow run . -profile docker   --input assets/one_sample.csv   --outdir results/one_sample   --taxonomy_enabled false   --phylogeny_enabled false   -resume -ansi-log false
```

### Tests and CI release workflow

`test` performs actual FastQC, MultiQC and Cutadapt on 20 synthetic reads and stops before QIIME 2. The output checker verifies read retention and poly-G removal. `test_full` includes QIIME 2 and phylogeny: use `-profile test_full,docker -stub-run` to test container wiring, or supply real CCS data with `--input` for actual analysis.

`test_stub` disables containers and checks the full graph. Always pass `-stub-run`. Its `.qza`/`.qzv` outputs and `classifier.stub` are placeholders, not biological results. Synthetic data does not validate DADA2 error learning or classifier accuracy.

GitHub Actions runs script checks, profile resolution, the full stub graph including taxonomy, and real Docker QC. A pushed version tag such as `v0.0.9` creates a release only after tests pass and the tag matches the manifest. Release notes come from [CHANGELOG.md](CHANGELOG.md). Tag creation/push is a separate maintainer action.

```bash
bash tests/test_python_and_shell.sh
nextflow config -profile singularity > resolved_nextflow.config.txt

nextflow run . -profile test_stub -stub-run   --taxonomy_enabled true --taxonomy_classifier tests/data/classifier.stub   --outdir results/stub
python3 tests/check_outputs.py results/stub --stub

nextflow run . -profile test,docker
python3 tests/check_outputs.py results/test
```

### Logs, outputs and reproducibility

For a long run, redirect terminal output to a log as below. Replace the input and classifier paths. Inspect `.nextflow.log` and the failing task's `work/.../.command.err` if execution fails. Resolve the error, then rerun with `-resume`.

Keep `work/`: QIIME results are published as hard links, and Nextflow also needs cached work directories for resuming. Record the pipeline revision, inputs, parameters, container versions and classifier. Once a release exists, use `-r <tag>` with the GitHub repository name to select it. Validate final QIIME artifacts before downstream interpretation.

Optional execution reports: `-with-report`, `-with-trace`, `-with-timeline`, `-with-dag`. Task metrics may require `ps` (procps/procps-ng) inside the image.

```bash
mkdir -p logs
nohup nextflow run . -profile docker   --input assets/my_samplesheet.csv   --taxonomy_classifier /absolute/path/to/compatible-classifier.qza   --outdir results/analysis   -resume -ansi-log false > logs/full_run.log 2>&1 &
tail -f logs/full_run.log
```

### Main outputs

Look under the directory selected by `--outdir`. Open FastQC/MultiQC HTML files in a browser. `.qza` files hold QIIME 2 artifacts; `.qzv` files hold visualizations. Taxonomy/phylogeny folders appear only when those stages run.

```text
results/
├── input_validation/
├── input_preparation/
├── raw_qc/
│   ├── fastqc/
│   └── multiqc/
├── read_cleanup/
├── clean_qc/
│   ├── fastqc/
│   └── multiqc/
├── cleanup_qc/
│   └── cleanup_qc_summary.tsv
├── qiime_import/
│   ├── qiime_manifest_ccs.tsv
│   ├── samples_raw.qza
│   └── samples_raw.demux.summary.qzv
├── qiime_dada2/
│   ├── dada2-ccs_table.qza
│   ├── dada2-ccs_table.qzv
│   ├── dada2-ccs_rep.qza
│   ├── dada2-ccs_rep.qzv
│   ├── dada2-ccs_stats.qza
│   └── dada2-ccs_stats.qzv
├── taxonomy/
│   └── <taxonomy_reference_id>/
│       ├── taxonomy.qza
│       ├── taxonomy.qzv
│       ├── taxonomy.tsv
│       └── taxonomy_barplot.qzv
└── phylogeny/
    ├── aligned-rep-seqs.qza
    ├── masked-aligned-rep-seqs.qza
    ├── unrooted-tree.qza
    └── rooted-tree.qza
```

---

<a id="korean"></a>

## 한국어

PacBio full-length 16S CCS read를 QIIME 2로 분석하는 Nextflow DSL2 파이프라인입니다. Docker·Singularity·Apptainer 실행 환경을 지원합니다.

### Nextflow가 처음이라면 여기부터 시작하세요

Nextflow는 여러 분석 단계를 연결하고 실행 순서를 관리하는 도구입니다. 이 파이프라인에서는 입력 read를 품질 검사와 QIIME 2 분석 단계에 순서대로 전달합니다. **컨테이너**는 분석에 필요한 프로그램을 묶은 실행 환경이며, Docker·Singularity·Apptainer는 이를 실행하는 도구입니다. 이 파이프라인을 사용하기 위해 Nextflow 코드를 직접 작성할 필요는 없습니다.

다음 공식 자료를 순서대로 참고하세요.

1. [Nextflow 소개 및 공식 문서](https://docs.seqera.io/nextflow): Nextflow가 어떤 역할을 하는지 확인합니다.
2. [공식 설치 안내](https://docs.seqera.io/nextflow/install): Java와 Nextflow 설치 및 명령어 경로 설정을 안내합니다.
3. [공식 교육 사이트](https://training.nextflow.io/): 기존 파이프라인 실행 방법은 **Nextflow Run** 과정부터 시작하세요. 사이트의 언어 메뉴에서 한국어도 선택할 수 있습니다.
4. [Hello Nextflow 입문 과정](https://training.nextflow.io/latest/hello_nextflow/): 파이프라인을 직접 작성하고 싶을 때 따라 해 볼 수 있는 실습입니다.

이 저장소를 실행하려면 Linux x86-64, Nextflow 26.04.2 이상, 호환되는 Java(CI에서는 Java 17 사용), 호스트 Python 3, Git, 컨테이너 실행 도구 하나가 필요합니다. 공용 서버에서는 관리자에게 사용 가능한 실행 도구를 확인하세요. 최초 컨테이너 다운로드에는 인터넷 연결과 저장 공간이 필요합니다. 입력 경로 확인은 호스트 Python에서, 분석 프로그램은 컨테이너에서 실행합니다.

터미널에서 설치 상태를 확인하세요. 아래 예시는 Docker 기준입니다. 서버에 설치된 도구에 맞게 선택하면 됩니다.

```bash
java -version
nextflow -version
python3 --version
git --version
docker --version
```

### 저장소 다운로드와 첫 테스트

먼저 저장소를 내려받고 해당 폴더로 이동하세요. 이후 명령어는 모두 이 폴더에서 실행하는 것을 기준으로 합니다. `nextflow run .`의 `.`은 “현재 폴더의 파이프라인을 실행한다”는 뜻입니다.

처음에는 저장소에 포함된 합성 데이터로 QC 테스트를 실행하세요. 본인의 시퀀싱 데이터나 분류용 classifier는 필요하지 않습니다. 처음 실행할 때는 컨테이너 다운로드 때문에 시간이 더 걸릴 수 있습니다. 검증에 성공하면 `PASS: QC outputs and poly-G removal`이 표시됩니다.

```bash
git clone https://github.com/KitHubb/amplicon_16S_rRNA_full-length_pacbio_qiime_nf.git
cd amplicon_16S_rRNA_full-length_pacbio_qiime_nf
nextflow run . -profile test,docker
python3 tests/check_outputs.py results/test
```

### 자주 사용하는 옵션

| 옵션 | 의미 |
|---|---|
| `-profile docker` | Docker로 실행합니다. 다른 도구라면 `singularity` 또는 `apptainer`를 사용하세요. |
| `-profile test,docker` | 소규모 테스트 설정과 Docker를 함께 적용합니다. 실행 도구는 하나만 선택하세요. |
| `--input` | 샘플 목록 CSV 파일의 경로입니다. |
| `--outdir` | 결과를 저장할 폴더입니다. |
| `--taxonomy_classifier` | 현재 QIIME 2와 호환되는 분류 모델 `.qza` 파일입니다. |
| `--taxonomy_enabled false` | classifier가 없을 때 분류 분석을 생략합니다. |
| `--phylogeny_enabled false` | 계통수 생성을 생략합니다. |
| `--stop_after_qc true` | QIIME 2 import 전에 QC까지만 수행합니다. |
| `-resume` | 재사용 가능한 이전 작업 결과를 활용합니다. `work/`와 `.nextflow/`를 보관하세요. |
| `-c local.config` | 로컬 설정을 추가합니다. 예: `nextflow -c local.config run . ...` |

하이픈 하나(`-`)는 Nextflow 자체 옵션, 두 개(`--`)는 이 파이프라인의 입력 설정입니다. 예시의 `/absolute/path/to/...`는 실제 파일 경로로 바꾸세요. 줄 끝의 `\`는 명령어가 다음 줄에도 이어진다는 뜻입니다.

### 분석 흐름 및 검증 환경

PacBio full-length 16S CCS/HiFi read를 분석합니다. DADA2는 기본적으로 설정된 primer 쌍, 길이 범위 1000–1600 bp, 16개 스레드를 사용합니다. 나머지 DADA2 옵션은 설치된 QIIME 2의 기본값을 따릅니다.

검증에 사용한 버전: Nextflow 26.04.2, Singularity-CE 3.9.2, FastQC 0.12.1, MultiQC 1.27.1, Cutadapt 5.2, QIIME 2 Amplicon 2025.7.

```text
TAR / HiFi FASTQ
  -> Samplesheet validation -> PacBio input preparation
  -> Raw FastQC / MultiQC
  -> Cutadapt quality trimming + poly-G/poly-A cleanup
  -> Clean FastQC / MultiQC + cleanup summary
  -> QIIME 2 single-end manifest / import
  -> DADA2 denoise-ccs -> Table / sequences / statistics summaries
  -> Taxonomy: SILVA classify-sklearn (optional)
  -> Phylogeny: MAFFT + FastTree (optional)
```

### 컨테이너 자동 다운로드와 로컬 이미지

Nextflow가 아래 버전의 공개 이미지를 자동으로 내려받습니다. QC 프로그램은 [BioContainers](https://bioconda.github.io/recipes/multiqc/README.html)를, QIIME 2는 DADA2·분류·계통수 플러그인이 포함된 [공식 배포 이미지](https://github.com/qiime2/distributions)를 사용합니다.

| 파라미터 | 기본 이미지 |
|---|---|
| `fastqc_container` | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0` |
| `multiqc_container` | `quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0` |
| `cutadapt_container` | `quay.io/biocontainers/cutadapt:5.2--py310h1fe012e_0` |
| `qiime_container` | `quay.io/qiime2/amplicon:2025.7` |

`docker` 대신 `singularity` 또는 `apptainer`를 선택하면 이미지 변환과 캐시를 자동으로 처리합니다. Docker에서는 호스트의 UID/GID로 실행하여 결과 파일이 사용자 계정에 속하도록 합니다. `_container` 파라미터로 호환 이미지나 digest로 고정한 이미지를 지정할 수도 있습니다.

기존 SIF 파일을 사용하려면 Singularity/Apptainer를 선택하고 `--qc_sif`, `--cutadapt_sif`, `--qiime_sif`를 지정하세요. 기본값은 null이며 Docker에서는 무시됩니다. QC 이미지는 FastQC와 MultiQC를 모두 포함해야 하고, Cutadapt 이미지는 Bash·gzip·tar도 포함해야 합니다. 서버별 설정은 Git에서 제외된 `local.config`에 보관하세요.

분류용 classifier는 포함되어 있지 않습니다. 기본 파라미터 YAML도 classifier 경로를 지정하지 않습니다.

### 입력 샘플 목록 준비

samplesheet는 “어떤 파일이 어떤 샘플에 해당하는지” 알려주는 CSV입니다. 아래 헤더를 정확히 사용하세요. 샘플 ID는 중복되면 안 되며 영문자·숫자로 시작하고 영문자·숫자·마침표·밑줄·하이픈을 사용할 수 있습니다. `assay_id`는 반드시 `16S_full`이어야 합니다.

입력 형식은 `fastq`(`.fastq`, `.fastq.gz`, `.fq`, `.fq.gz`) 또는 `tar`(샘플별 FASTQ 파일을 담은 `.tar`)입니다. 상대 경로는 원본 samplesheet가 있는 폴더를 기준으로 해석하며 절대 경로도 가능합니다.

TAR는 샘플별로 압축을 풀고 파일명에 `_trim_`이 들어간 파일을 제외한 다음, 나머지를 `<sample_id>.raw.fastq.gz`로 정리합니다. 원본 입력 파일은 변경하지 않습니다.

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
Sample01,Run01,16S_full,1,Stool,tar,/data/FASTQ/Run01/Sample01_cell1.tar
Sample02,Run01,16S_full,1,Stool,fastq,/data/FASTQ/Run01/Sample02_HiFi.fastq.gz
```

### 폴더에서 samplesheet 생성

도우미 스크립트의 인자는 입력 폴더, 출력 CSV, run ID, 입력 형식, library round, sample type 순서입니다. 예시를 본인 데이터에 맞게 바꾸세요. 생성 후 샘플 ID와 메타데이터가 맞는지 반드시 확인하세요.

```bash
bash bin/make_samplesheet.sh   /data/FASTQ/Run01   assets/my_samplesheet.csv   Run01 tar 1 Stool
```

### 본인 데이터 분석하기

호환 classifier가 아직 없다면 먼저 분류 분석을 끄고 실행하세요. 아래 예시는 계통수 분석을 유지합니다. 자원이 작은 컴퓨터에서는 합성 데이터 테스트부터 실행하세요. 실제 분석의 DADA2 기본 요청량은 CPU 16개와 메모리 32 GB이며 다른 작업도 자원을 사용합니다.

```bash
nextflow run . -profile docker   --input assets/my_samplesheet.csv   --outdir results/analysis   --taxonomy_enabled false   -resume
```

### 분류 분석 활성화

QIIME 2 Amplicon 2025.7과 호환되는 classifier를 지정하세요. 기존 검증 환경에서는 SILVA 138 99% Naive Bayes 모델인 `silva-138-99-nb-classifier.qza`를 사용했습니다. 파일명이 같다고 호환성이 보장되는 것은 아닙니다. 분류 분석과 계통수 분석은 기본으로 활성화되어 있으며 각각 끌 수 있습니다.

```bash
nextflow run . -profile docker   --input assets/my_samplesheet.csv   --taxonomy_classifier /absolute/path/to/compatible-classifier.qza   --outdir results/analysis   -resume
```

### 실제 샘플 하나로 먼저 실행

앞 단계에서 준비한 samplesheet를 사용하세요. 아래 명령은 상대 입력 경로가 유지되도록 같은 폴더에 샘플 하나짜리 CSV를 만듭니다. 먼저 핵심 분석을 확인한 후 위 분류 분석 예시에 이 입력 파일을 넣어 후속 분석을 활성화하세요.

```bash
{
  head -n 1 assets/my_samplesheet.csv
  sed -n '2p' assets/my_samplesheet.csv
} > assets/one_sample.csv

nextflow run . -profile docker   --input assets/one_sample.csv   --outdir results/one_sample   --taxonomy_enabled false   --phylogeny_enabled false   -resume -ansi-log false
```

### 테스트 및 CI 릴리스

`test`는 합성 read 20개로 FastQC·MultiQC·Cutadapt를 실제 실행하고 QIIME 2 전에 종료합니다. 출력 검사에서는 read 보존과 poly-G 제거를 확인합니다. `test_full`은 QIIME 2와 계통수까지 포함합니다. 컨테이너 연결 확인에는 `-profile test_full,docker -stub-run`을, 실제 분석에는 `--input`으로 실제 CCS 데이터를 지정하세요.

`test_stub`는 컨테이너를 끄고 전체 단계의 연결을 검사합니다. 반드시 `-stub-run`을 함께 사용하세요. 생성되는 `.qza`/`.qzv` 및 `classifier.stub`는 테스트용 자리표시자이며 생물학적 분석 결과가 아닙니다. 합성 데이터 테스트는 DADA2 오류 모델 학습이나 classifier 정확도를 검증하지 않습니다.

GitHub Actions는 스크립트 검사, 프로필 해석, 분류 단계를 포함한 전체 stub 테스트, 실제 Docker QC를 수행합니다. `v0.0.9` 같은 버전 태그를 push하면 검사 통과 및 manifest 버전 일치 후 릴리스를 생성합니다. 릴리스 노트는 [CHANGELOG.md](CHANGELOG.md)에서 가져옵니다. 태그 생성과 push는 관리자가 별도로 수행합니다.

```bash
bash tests/test_python_and_shell.sh
nextflow config -profile singularity > resolved_nextflow.config.txt

nextflow run . -profile test_stub -stub-run   --taxonomy_enabled true --taxonomy_classifier tests/data/classifier.stub   --outdir results/stub
python3 tests/check_outputs.py results/stub --stub

nextflow run . -profile test,docker
python3 tests/check_outputs.py results/test
```

### 로그·결과 파일·재현성

오래 걸리는 분석은 아래처럼 터미널 출력을 로그로 저장할 수 있습니다. 입력 및 classifier 경로는 실제 값으로 바꾸세요. 실패하면 `.nextflow.log`와 실패한 작업의 `work/.../.command.err`를 확인하고, 원인을 해결한 뒤 `-resume`으로 다시 실행하세요.

`work/`를 보관하세요. QIIME 결과는 하드 링크로 게시되며 Nextflow가 재개할 때도 작업 캐시가 필요합니다. 사용한 파이프라인 커밋, 입력, 파라미터, 컨테이너 버전, classifier를 기록하세요. 릴리스가 게시된 후에는 GitHub 저장소 이름으로 실행할 때 `-r <태그>`로 버전을 선택할 수 있습니다. 후속 해석 전 최종 QIIME artifact를 검증하세요.

실행 보고서는 `-with-report`, `-with-trace`, `-with-timeline`, `-with-dag`로 추가합니다. 작업 사용량 측정에는 컨테이너 안의 `ps`(procps/procps-ng)가 필요할 수 있습니다.

```bash
mkdir -p logs
nohup nextflow run . -profile docker   --input assets/my_samplesheet.csv   --taxonomy_classifier /absolute/path/to/compatible-classifier.qza   --outdir results/analysis   -resume -ansi-log false > logs/full_run.log 2>&1 &
tail -f logs/full_run.log
```

### 주요 결과물

`--outdir`로 지정한 폴더에서 결과를 확인하세요. FastQC·MultiQC의 HTML 파일은 브라우저에서 열 수 있습니다. `.qza`는 QIIME 2 분석 데이터, `.qzv`는 시각화 파일입니다. 분류·계통수 폴더는 해당 단계를 실행했을 때 생성됩니다.

```text
results/
├── input_validation/
├── input_preparation/
├── raw_qc/
│   ├── fastqc/
│   └── multiqc/
├── read_cleanup/
├── clean_qc/
│   ├── fastqc/
│   └── multiqc/
├── cleanup_qc/
│   └── cleanup_qc_summary.tsv
├── qiime_import/
│   ├── qiime_manifest_ccs.tsv
│   ├── samples_raw.qza
│   └── samples_raw.demux.summary.qzv
├── qiime_dada2/
│   ├── dada2-ccs_table.qza
│   ├── dada2-ccs_table.qzv
│   ├── dada2-ccs_rep.qza
│   ├── dada2-ccs_rep.qzv
│   ├── dada2-ccs_stats.qza
│   └── dada2-ccs_stats.qzv
├── taxonomy/
│   └── <taxonomy_reference_id>/
│       ├── taxonomy.qza
│       ├── taxonomy.qzv
│       ├── taxonomy.tsv
│       └── taxonomy_barplot.qzv
└── phylogeny/
    ├── aligned-rep-seqs.qza
    ├── masked-aligned-rep-seqs.qza
    ├── unrooted-tree.qza
    └── rooted-tree.qza
```
